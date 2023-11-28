#!/usr/bin/env python3

from enum import IntEnum
import os
import os.path as osp
from pathlib import Path
import threading

from pybsc.ssh import SSHExecutor
import cv2
from pybsc import current_time_str
from pybsc import makedirs
import openai
from openai.openai_object import OpenAIObject
from ros_speak import speak_jp
import rospy
from speech_recognition_msgs.msg import SpeechRecognitionCandidates

from jsk_teaching_object.take_action_client import take_action
from jsk_teaching_object.take_image_photo_client import take_image_photo
from jsk_teaching_object.topic_subscriber import ImageSubscriber
from jsk_teaching_object.update_model_client import update_model


def train_in_remote(
        image_directory,
        output,
        username="iory", ip='133.11.216.13',
        bastion_username='iory', bastion_ip='dlbox2.jsk.imi.i.u-tokyo.ac.jp',
        output_username=None, output_ip=None,
        identity_file=osp.join(osp.expanduser('~'), '.ssh', 'id_rsa'),
        epoch=3,
        batchsize=16):
    client = SSHExecutor(ip, username,
                         key_filepath=identity_file,
                         bastion_host=bastion_ip,
                         bastion_user=bastion_username)
    remote_image_path = f'/tmp/thk'
    session_name = 'project-t'
    client.rsync(image_directory,
                 remote_image_path)
    client.execute_command("rm -rf /tmp/thk/gen_data/train*")
    client.execute_command_tmux(
        f'cd /home/iory/jsk_teaching_object/src/jsk_demos/train && python generate_data.py --from-images-dir {remote_image_path}/{Path(image_directory).name} --min-scale 0.2 --max-scale 0.6 -n 4000 --out {remote_image_path}/gen_data',
        session_name=session_name)
    trained_model_path = os.path.join(remote_image_path,
                                      'gen_data', 'train',
                                      'weights', 'best.pt')
    client.watch_dog(trained_model_path)
    client.kill_tmux_session(session_name)
    client.rsync(output,
                 trained_model_path,
                 is_upload=False)
    return output


def train(image_directory, volume):
    filename = '{}.pt'.format(current_time_str())
    saved_weight_filepath = train_in_remote(
        image_directory=str(image_directory),
        output=osp.join(
            osp.expanduser('~'), 'dataset', '2023-09-21', filename))
    rospy.loginfo(
        'Model saved {}'.format(saved_weight_filepath))
    update_model('/object_detection/update_model', saved_weight_filepath, '')
    speak_jp('モデルの更新を行いました。', wait=True, volume=volume)


class STATE(IntEnum):
    START = 0
    WAIT_LABEL = 1
    SAVE_PHOTO = 2
    REMOVE_OBJECT = 3
    ASK_CONTINUE = 4
    UPDATE_MODEL = 5


class RegisterObject(object):

    def __init__(self):
        openai.api_key = os.environ['OPENAI_KEY']

        self.volume = rospy.get_param('~volume', 0.1)
        self.root_image_path = Path(rospy.get_param('~root_image_path'))
        makedirs(self.root_image_path)
        self.image_subscriber = ImageSubscriber('~image')
        self.current_label_name = None

        self.speech_msg = None
        self.state = STATE.START

        self.speech_sub = rospy.Subscriber(
            "/speech_to_text", SpeechRecognitionCandidates,
            callback=self.speech_callback, queue_size=1)

    def speech_callback(self, msg):
        self.speech_msg = msg

    def request(self, prompt: str, retry: int = 5) -> OpenAIObject:
        for t in range(retry):
            try:
                rospy.loginfo("OpenAI trying request... {}/{}".format(t+1, retry))
                res: OpenAIObject = openai.Completion.create(
                    model="text-davinci-003",
                    prompt=prompt,
                    temperature=0.0,
                    top_p=1,
                    max_tokens=2048
                )
            except (openai.APIError, openai.error.RateLimitError) as e:
                rospy.logwarn("Caught OpenAI APIError: {}".format(str(e)))
            else:
                break
        return res

    def speak(self, msg, wait=True):
        rospy.loginfo(msg)
        speak_jp(msg, wait=wait, volume=self.volume)

    def start(self):
        self.speak('物品を登録しますか。')
        self.speech_msg = None

        base = "あなたは日本語の対話システムです。システム(あなた)の「物品を登録しますか？」というメッセージに対してユーザーが返答します。ユーザーの返答を受け取り、ユーザーが物品の登録をすると判断した場合は「1」を、そうでないならば「2」を返答してください。"
        base += 'ユーザーがもう一度言ってほしいと聞き返した場合には4を返してください。ユーザーが物体の学習をしてほしいと言った場合には5を返してください。ユーザーが「認識して」などの認識結果を見せるように言った場合には6を返してください。'
        rate = rospy.Rate(10)
        while not rospy.is_shutdown():
            if self.speech_msg is not None:
                input_text = self.speech_msg.transcript[0]
                self.speech_msg = None
                prompt = base + 'User: "{}" あなたの回答を[1, 2, 4, 5, 6]のどれかのみで返してください。 A: '.format(input_text)
                prompt = " ".join(prompt.split("\n"))
                rospy.loginfo(prompt)
                res = self.request(prompt)
                answer = res.get('choices')[0].get('text').lstrip()
                rospy.loginfo(answer)
                if answer == '6':
                    self.speak('認識結果を見せますね。')
                    take_action('/r8_5_look_server/take_action', wait=True)
                elif answer == '4':
                    self.speak('物品を登録しますか。')
                elif answer == '5':
                    self.update_model()
                elif answer == '1':
                    self.speak('物品を登録しますね')
                    break
                else:
                    self.speak('物品を登録する場合は言ってください。')
            rate.sleep()
        self.state = STATE.WAIT_LABEL

    def reconfirm(self, label_name):
        self.speak('これは「{}」という名前ですか？'.format(label_name))
        base = "あなたは日本語の対話システムです。システム(あなた)の「これは{}ですね」というメッセージに対してユーザーが返答します。ユーザーの返答を受け取り、合っている場合には1を合ってない場合には2を、良くわからない返答の場合には3を返してください。".format(label_name)
        base += 'ユーザーがもう一度言ってほしいというようなことを聞き返した場合には4を返してください。ユーザーが終了してというような場合には5を返してください。'

        rate = rospy.Rate(10)
        while not rospy.is_shutdown():
            if self.speech_msg is not None:
                input_text = self.speech_msg.transcript[0]
                self.speech_msg = None
                prompt = base + 'User: "{}" A: '.format(input_text)
                prompt = " ".join(prompt.split("\n"))
                rospy.loginfo(prompt)
                res = self.request(prompt)
                answer = res.get('choices')[0].get('text').lstrip().rstrip()
                rospy.loginfo(answer)
                if answer.lower() == '5':
                    self.state = STATE.START
                    break
                elif answer.lower() == '4':
                    self.speak('これは「{}」という名前ですか？'.format(label_name))
                    continue
                elif answer.lower() == '1':
                    self.speak('ありがとうございます。「{}」ですね'.format(label_name))
                    self.current_label_name = label_name
                    self.state = STATE.SAVE_PHOTO
                    break
                elif answer.lower() == '3':
                    self.speak('これは「{}」という名前ですか？'.format(label_name))
                else:
                    self.state = STATE.WAIT_LABEL
                    break
            rate.sleep()

    def wait_label(self):
        self.speak('ラベル名を教えてください。')
        self.speech_msg = None

        base = "あなたは日本語の対話システムです。システム(あなた)の「ラベル名を教えてください。」というメッセージに対してユーザーが返答します。ユーザーの返答を受け取り、「ラベル名」に該当する文字列のみを返してください。これはマイクですという場合には「マイク」という文字列のみを返してください。"
        base += 'ユーザーがラベル名を言っていない場合には3を返してください。ユーザーが終了してというような場合には5を返してください。'
        # base += 'ユーザーがもう一度言ってほしいというようなことを聞き返した場合には4という文字のみを返してください。'
        rate = rospy.Rate(10)
        while not rospy.is_shutdown():
            if self.speech_msg is not None:
                input_text = self.speech_msg.transcript[0]
                self.speech_msg = None
                prompt = base + 'User: "{}" ラベル名: '.format(input_text)
                prompt = " ".join(prompt.split("\n"))
                rospy.loginfo(prompt)
                res = self.request(prompt)
                answer = res.get('choices')[0].get('text').lstrip().rstrip()
                if answer == '5':
                    self.state = STATE.START
                    break
                elif answer == '3':
                    self.speak('ラベル名を教えてください。')
                    continue
                rospy.loginfo(answer)
                self.reconfirm(answer)
                break
            rate.sleep()

    def save_photo(self):
        self.speak('物体の画像を撮ります。物体を置いてください。準備ができたら画像を撮るよう言ってください')
        self.speech_msg = None

        base = 'あなたは日本語の対話システムです。システム(あなた)の「続いて画像を撮影しますか？」というメッセージに対してユーザーが返答します。ユーザーの返答を受け取り、ユーザーが画像の撮影を続けると判断した場合は「"1"」を、ユーザーが画像の撮影を終了する場合は「"2"」を、ユーザーのメッセージが撮影の続行に関係のない答えならば「"3"」を返答してください。A:のあとに続く回答を["1", "2", "3"]のどれかのみから選んで返答してください。あなたの返答は1文字のみです。 Example 1: User: 続けて A: 1 Example 2: User: 終了 A: 2 Example 3: User: 今日は良い天気です A: 3 Example 4: User: めちゃあつい A: 3 Example 5: User: foo A: 3 Example 6: User: 撮影して A: 1 Example 7: User: 止めて A: 2 Example 8: User: とって A: 1  Example 9: User: 撮影してください A: 1 '
        base += 'ユーザーがもう一度言ってほしいというようなことを聞き返した場合には4を返してください。学習してほしいとユーザーが言ってきた場合には5を返してください。'
        base += 'ユーザーの回答は以下です。 User: {} あなたの回答を[1, 2, 3, 4, 5]のどれかで返してください。 A:'
        rate = rospy.Rate(10)
        while not rospy.is_shutdown():
            if self.speech_msg is not None:
                input_text = self.speech_msg.transcript[0]
                self.speech_msg = None
                prompt = base.format(input_text)
                prompt = " ".join(prompt.split("\n"))
                rospy.loginfo(prompt)
                res = self.request(prompt)
                answer = res.get('choices')[0].get('text').lstrip().rstrip()
                rospy.loginfo(answer)

                if answer.lower() == '5':
                    self.update_model()
                    self.state = STATE.START
                    break
                elif answer.lower() == '4':
                    self.speak('物体の画像を撮ります。物体を置いてください。準備ができたら画像を撮るよう言ってください')
                elif answer.lower() == '1':
                    self.image_subscriber.msg = None

                    take_image_photo(
                        '/r8_5_look_server/take_image_photo',
                        '/usb_cam/image_raw',
                        str(self.root_image_path / self.current_label_name),
                        wait=True)

                    # self.speak('画像を撮影しますね')
                    # self.speak('さん、にーー、いち')
                    # speak_jp('package://rostwitter/resource/camera.wav', wait=True)

                    # img = self.image_subscriber.take_image('bgra8')
                    # if img is None:
                    #     self.speak('画像が取得できませんでした。画像トピックを確認してください。',
                    #                wait=True)
                    #     continue
                    # makedirs(self.root_image_path / self.current_label_name)
                    # cv2.imwrite(str(self.root_image_path / self.current_label_name / '{}.jpg'.format(current_time_str())), img)
                    # self.speak('画像を保存しました', wait=True)
                    # self.speak('続いてどうしますか。')
                    self.state = STATE.ASK_CONTINUE
                    break
                elif answer.lower() == '2':
                    self.speak('写真を撮るのを終了します')
                    self.state = STATE.ASK_CONTINUE
                    break
                else:
                    self.speak('すいません、良くわかりませんでした。物体の画像を取りますか。')
            rate.sleep()

    def ask_continue(self):
        self.speak('他の物体を登録しますか？')
        self.speech_msg = None

        base = 'あなたは日本語の対話システムです。システム(あなた)の「他の物体を登録しますか？」というメッセージに対してユーザーが返答します。ユーザーの返答を受け取り、ユーザーが他の物体を登録すると判断した場合は「"1"」を、ユーザーが終了する場合は「"2"」を、ユーザがモデルを学習する場合には「"2"」を、ユーザーのメッセージが続行に関係のない答えならば「"3"」を返答してください。'
        base += 'ユーザーがもう一度言ってほしいというようなことを聞き返した場合には4を返してください'
        base += """
Example 1:
User: いいえ
A: 2

Example 2:
User: 終了
A: 2

Example 3:
User: 登録します
A: 1

Example 4:
User: 学習して
A: 2
        """
        rate = rospy.Rate(10)
        while not rospy.is_shutdown():
            if self.speech_msg is not None:
                input_text = self.speech_msg.transcript[0]
                self.speech_msg = None
                prompt = base + "User: {} A:".format(input_text)
                prompt = " ".join(prompt.split("\n"))
                rospy.loginfo(prompt)
                res = self.request(prompt)
                answer = res.get('choices')[0].get('text').lstrip().rstrip()
                rospy.loginfo(answer)

                if answer.lower() == '4':
                    self.speak('他の物体を登録しますか？')
                    continue
                elif answer.lower() == '1':
                    self.speak('分かりました。')
                    self.state = STATE.WAIT_LABEL
                    break
                elif answer.lower() == '2':
                    self.speak('終了します')
                    self.state = STATE.UPDATE_MODEL
                    break
                else:
                    self.speak('すいません、良くわかりませんでした。他の物体を登録しますか？')
            rate.sleep()

    def update_model(self):
        self.speak('物体を学習します。時間がかかりますがお待ちください。', wait=True)
        # tmp_path = '/home/iory/src/github.com/jsk-ros-pkg/jsk_demos/train/tiny_yamagata_items'
        # t = threading.Thread(target=train, args=(tmp_path,))
        t = threading.Thread(target=train, args=(self.root_image_path,
                                                 self.volume))
        t.start()
        # t.join()
        self.state = STATE.START

    def current_state(self):
        if self.state == STATE.START:
            self.start()
        elif self.state == STATE.WAIT_LABEL:
            self.wait_label()
        elif self.state == STATE.SAVE_PHOTO:
            self.save_photo()
        elif self.state == STATE.ASK_CONTINUE:
            self.ask_continue()
        elif self.state == STATE.UPDATE_MODEL:
            self.update_model()

    def run(self):
        rate = rospy.Rate(10)
        while not rospy.is_shutdown():
            self.current_state()
            rate.sleep()


if __name__ == '__main__':
    rospy.init_node('register_object')
    parser = RegisterObject()
    parser.run()
