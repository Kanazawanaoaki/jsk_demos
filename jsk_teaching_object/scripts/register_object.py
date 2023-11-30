#!/usr/bin/env python3

from enum import IntEnum
import time
import os
import os.path as osp
from pathlib import Path
import threading

from pybsc.ssh import SSHExecutor
from pybsc import current_time_str
from pybsc import makedirs
import openai
from openai.openai_object import OpenAIObject
from ros_speak import speak_jp
import rospy
from speech_recognition_msgs.msg import SpeechRecognitionCandidates

from jsk_teaching_object.take_action_client import take_action
from jsk_teaching_object.take_image_photo_client import take_image_photo
from jsk_teaching_object.update_model_client import update_model


openai.api_key = os.environ['OPENAI_KEY']


def request(prompt: str, retry: int = 5) -> OpenAIObject:
    for t in range(retry):
        try:
            rospy.loginfo("OpenAI trying request... {}/{}".format(
                t + 1, retry))
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


def train_in_remote(
        image_directory,
        output,
        username="iory", ip='133.11.216.103',
        bastion_username='iory', bastion_ip='dlbox2.jsk.imi.i.u-tokyo.ac.jp',
        output_username=None, output_ip=None,
        identity_file=osp.join(osp.expanduser('~'), '.ssh', 'id_rsa'),
        epoch=3,
        batchsize=16,
        condition=None):
    client = SSHExecutor(ip, username,
                         key_filepath=identity_file,
                         bastion_host=bastion_ip,
                         bastion_user=bastion_username)
    remote_image_path = '/home/iory/irex'
    session_name = 'project-t'
    client.rsync(image_directory,
                 remote_image_path)
    client.execute_command("rm -rf {}/gen_data/train*".format(remote_image_path))
    client.execute_command_tmux(
        f'cd /home/iory/jsk_teaching_object/src/jsk_demos/train && python generate_data.py --from-images-dir {remote_image_path}/{Path(image_directory).name} --min-scale 0.2 --max-scale 0.6 -n 4000 --out {remote_image_path}/gen_data --epoch {epoch}',  # NOQA
        session_name=session_name)
    trained_model_path = os.path.join(remote_image_path,
                                      'gen_data', 'train',
                                      'weights', 'best.pt')
    ret = client.watch_dog(trained_model_path, condition=condition)
    time.sleep(5.0)
    client.kill_tmux_session(session_name)
    if ret is False:
        return False
    client.rsync(output,
                 trained_model_path,
                 is_upload=False)
    return output


class BaseState(IntEnum):
    REGISTER_OBJECT = 1
    REGISTER_OBJECT_END = 2
    RESPEAKING = 3
    TRAIN = 4
    SHOW_INFERENCE = 5
    ASK_WHAT = 6
    SAVE_PHOTO = 7
    NONE = 8
    WAIT_LABEL = 9
    AUTO_DEMO = 10


base_prompt = "あなたは日本語の対話システムです。システム（あなた）は、ユーザーに様々なメッセージを送り、ユーザーの返答を受け取ります。ユーザーの返答に基づき、以下の指示に従って適切な数字を返答してください。ユーザーが物品を登録する意思がある場合は「1」を返答。ユーザーが物品登録を終了する場合は「2」を返答。ユーザーがもう一度言ってほしいと言う場合は「3」を返答。ユーザーが物体モデルの学習を希望する場合は「4」を返答。ユーザーが認識結果を見せるように言う場合は「5」を返答。ユーザーが何ができるかを尋ねた場合には「6」を返答。ユーザーが画像撮影を続ける準備ができた場合は「7」、オートデモをするように依頼された場合は「10」、それ以外の返答の場合は「8」を返答。ユーザーの返答は以下です。数字のみを返答してください。"  # NOQA


state_words = {
    BaseState.REGISTER_OBJECT.value: '物品を登録しますか？',
    BaseState.REGISTER_OBJECT_END.value: '物品を登録しますか？',
    BaseState.SAVE_PHOTO.value: '物体の画像を撮ります。物体を置いてください。準備ができたら画像を撮るよう言ってください',
}



class RegisterObject(object):

    def __init__(self):
        self.volume = rospy.get_param('~volume', 0.1)
        self.root_image_path = Path(rospy.get_param('~root_image_path'))
        makedirs(self.root_image_path)
        self.current_label_name = None

        self.thread = None
        self.stop_thread = threading.Event()

        self.speech_msg = None
        self.state = BaseState.REGISTER_OBJECT

        self.speech_sub = rospy.Subscriber(
            "/speech_to_text", SpeechRecognitionCandidates,
            callback=self.speech_callback, queue_size=1)

    def speech_callback(self, msg):
        self.speech_msg = msg

    def speak(self, msg, wait=True):
        rospy.loginfo(msg)
        speak_jp(msg, wait=wait, volume=self.volume)

    def train(self, image_directory):
        filename = '{}.pt'.format(current_time_str())
        makedirs(osp.join(osp.expanduser('~'), 'dataset', '2023-09-21'))
        saved_weight_filepath = train_in_remote(
            image_directory=str(image_directory),
            output=osp.join(
                osp.expanduser('~'), 'dataset', '2023-09-21', filename),
            condition=lambda: not self.stop_thread.is_set())
        if saved_weight_filepath is False:
            return
        rospy.loginfo(
            'Model saved {}'.format(saved_weight_filepath))
        update_model('/object_detection/update_model', saved_weight_filepath, '')
        self.speak('モデルの更新を行いました。認識結果を見せてと言うと結果を確認しますよ。',
                   wait=True)

    def update_model(self):
        self.speak('物体を学習します。時間がかかりますがお待ちください。', wait=True)

        if self.thread and self.thread.is_alive():
            rospy.loginfo('Stop previous thread.')
            self.stop_thread.set()
            self.thread.join()
            rospy.loginfo('Stopped previous thread.')

        self.stop_thread.clear()
        self.thread = threading.Thread(
            target=self.train, args=(self.root_image_path,))
        self.thread.start()
        self.state = BaseState.REGISTER_OBJECT

    def show_inference(self):
        self.speak('認識結果を見せますね。')
        take_action('/r8_5_look_server/take_action', wait=True)

    def save_photo(self):
        self.speak('物体の画像を撮ります。しょうしょうお待ちください。')
        take_image_photo(
            '/r8_5_look_server/take_image_photo',
            '/usb_cam/image_raw',
            str(self.root_image_path / self.current_label_name),
            wait=True)

    def current_state(self):
        if self.state == BaseState.REGISTER_OBJECT.value:
            self.base_state()
        elif self.state == BaseState.WAIT_LABEL.value:
            self.wait_label()
        elif self.state == BaseState.SAVE_PHOTO.value:
            self.base_state()
        elif self.state == BaseState.ASK_CONTINUE.value:
            self.base_state()
        elif self.state == BaseState.UPDATE_MODEL.value:
            self.base_state()
        elif self.state == BaseState.AUTO_DEMO.value:
            self.base_state()

    def run(self):
        rate = rospy.Rate(10)
        while not rospy.is_shutdown():
            self.current_state()
            rate.sleep()

    def base_state(self):
        self.speak(state_words[self.state])
        self.speech_msg = None

        rate = rospy.Rate(10)
        while not rospy.is_shutdown():
            rate.sleep()
            if self.speech_msg is None:
                if self.state == BaseState.AUTO_DEMO.value:
                    take_image_photo(
                        '/r8_5_look_server/take_image_photo',
                        '/usb_cam/image_raw', '',
                        wait=True)
                    self.speak(state_words[BaseState.REGISTER_OBJECT.value])
                    rospy.sleep(10.0)
                continue

            input_text = self.speech_msg.transcript[0]
            self.speech_msg = None
            prompt = base_prompt + 'User: "{}" Answer: '.format(input_text)
            rospy.loginfo(prompt)
            answer = None
            for _ in range(5):
                res = request(prompt)
                answer = res.get('choices')[0].get('text').lstrip()
                try:
                    answer = int(answer)
                except Exception as e:
                    rospy.logwarn("{}".format(e))
                break

            rospy.loginfo(answer)
            if self.state == BaseState.SAVE_PHOTO.value and answer == BaseState.SAVE_PHOTO.value:
                self.save_photo()
                self.state = BaseState.REGISTER_OBJECT
                break
            elif answer == BaseState.REGISTER_OBJECT.value:
                self.speak('物品を登録しますね')
                self.state = BaseState.WAIT_LABEL
                break
            elif answer == BaseState.REGISTER_OBJECT_END.value:
                break
            elif answer == BaseState.TRAIN.value:
                self.update_model()
                break
            elif answer == BaseState.SHOW_INFERENCE.value:
                self.show_inference()
            elif answer == BaseState.ASK_WHAT.value:
                self.speak("私は物体の画像を手についたカメラで撮影してデータベースに蓄えて学習することができます。「物体を登録して」や「学習して」、「認識結果を見せて」など言ってみてください。")
            elif answer == BaseState.AUTO_DEMO.value:
                self.prev_state = self.state
                self.state = BaseState.AUTO_DEMO.value
                take_image_photo(
                    '/r8_5_look_server/take_image_photo',
                    '/usb_cam/image_raw', '',
                    wait=True)
                self.speak(state_words[BaseState.REGISTER_OBJECT.value])
                rospy.sleep(10.0)
            else:
                self.speak('すいません、うまく解釈することができませんでした。言い方を変えてみてください。')
                rospy.sleep(3.0)

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
                res = request(prompt)
                answer = res.get('choices')[0].get('text').lstrip().rstrip()
                rospy.loginfo(answer)
                if answer.lower() == '5':
                    self.state = BaseState.REGISTER_OBJECT
                    break
                elif answer.lower() == '4':
                    self.speak('これは「{}」という名前ですか？'.format(label_name))
                    continue
                elif answer.lower() == '1':
                    self.speak('ありがとうございます。「{}」ですね'.format(label_name))
                    self.current_label_name = label_name
                    self.state = BaseState.SAVE_PHOTO
                    break
                elif answer.lower() == '3':
                    self.speak('これは「{}」という名前ですか？'.format(label_name))
                else:
                    self.state = BaseState.WAIT_LABEL
                    break
            rate.sleep()

    def wait_label(self):
        self.speak('ラベル名を教えてください。')
        self.speech_msg = None

        base = "あなたは日本語の対話システムです。システム(あなた)の「ラベル名を教えてください。」というメッセージに対してユーザーが返答します。ユーザーの返答を受け取り、「ラベル名」に該当する文字列のみを返してください。これはマイクですという場合には「マイク」という文字列のみを返してください。"
        base += 'ユーザーがラベル名を言っていない場合には3を返してください。ユーザーが終了してというような場合には5を返してください。'
        rate = rospy.Rate(10)
        while not rospy.is_shutdown():
            if self.speech_msg is not None:
                input_text = self.speech_msg.transcript[0]
                self.speech_msg = None
                prompt = base + 'User: "{}" ラベル名: '.format(input_text)
                prompt = " ".join(prompt.split("\n"))
                rospy.loginfo(prompt)
                res = request(prompt)
                answer = res.get('choices')[0].get('text').lstrip().rstrip()
                if answer == '5':
                    self.state = BaseState.REGISTER_OBJECT
                    break
                elif answer == '3':
                    self.speak('ラベル名を教えてください。')
                    continue
                rospy.loginfo(answer)
                self.reconfirm(answer)
                break
            rate.sleep()


if __name__ == '__main__':
    rospy.init_node('register_object')
    parser = RegisterObject()
    parser.run()
