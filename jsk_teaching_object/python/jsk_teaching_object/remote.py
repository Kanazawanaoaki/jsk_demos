import datetime
import os
import os.path as osp
from pathlib import Path
import subprocess
import sys
import tempfile
import time

from eos import current_time_str
from eos import makedirs
from pybsc import run_command
import six


def run_ssh_task(
        image_directory,
        username="iory", bastion_username="iory", bastion_ip="dlbox2.jsk.imi.i.u-tokyo.ac.jp",
        output_ip="", output_username="", ip='133.11.216.78', epoch=10,
        identity_file=osp.join(osp.expanduser('~'), '.ssh', 'id_rsa'), output='',
        batchsize=16,
):
    proxy_command = "ssh -i {} -o ProxyCommand='ssh -i {} -W %h:%p {}@{}'".format(
        identity_file, identity_file, bastion_username, bastion_ip)
    ssh_target = '{}@{}'.format(username, ip)
    ssh_command = "{} -i {} {}@{}".format(proxy_command, identity_file, username, ip)

    output_to_remote = False
    if len(output_ip) > 0 and len(output_username) > 0:
        tmp_output = tempfile.TemporaryDirectory()
        makedirs(osp.join(tmp_output.name, osp.dirname(output)))
        output_to_remote = True

    if output_to_remote is False and len(output) > 0:
        output = output.rstrip('/')
        makedirs(osp.dirname(output))

    project_id = current_time_str()
    tmp_dir = osp.join('/tmp', 'project-t', '{}'.format(project_id))
    a = run_command('{} mkdir -p {}'.format(ssh_command, tmp_dir), shell=True)

    source_image_dir = image_directory.rstrip('/')
    rsync_image_command = 'rsync -e "{}" --verbose -r {} {}:{}'.format(
        proxy_command, source_image_dir, ssh_target, tmp_dir)
    run_command(rsync_image_command, shell=True)
    source_image_dir_in_remote = osp.join(tmp_dir, osp.basename(source_image_dir))

    session_name = project_id
    run_command(ssh_command + ' ' + ' '.join(["tmux", "new-session", "-d", "-s", session_name]), shell=True)
    command = f'cd /home/iory/src/github.com/iory/jsk_demos/train && python generate_data.py --from-images-dir {source_image_dir_in_remote} -b {batchsize} --epoch {epoch} --compress-annotation-data'
    run_command(ssh_command + ' ' + '"' + ' '.join(["tmux", "send-keys", "-t", session_name, "'{}'".format(command), "Enter"]) + '"', shell=True)
    return source_image_dir_in_remote, session_name


def watchdog(bastion_username, bastion_ip, username, ip, remote_file_path, identity_filepath=None, poll_interval=5):
    if identity_filepath is None:
        identity_filepath = osp.join(osp.expanduser('~'), '.ssh', 'id_rsa')

    proxy_command = "ssh -i {} -o ProxyCommand='ssh -i {} -W %h:%p {}@{}'".format(
        identity_filepath, identity_filepath, bastion_username, bastion_ip)

    ssh_command = "{} -i {} {}@{}".format(proxy_command, identity_filepath, username, ip)

    check_file_cmd = f"{ssh_command} test -f {remote_file_path} && echo exists || echo not_exists"

    while True:
        result = run_command(check_file_cmd, shell=True, capture_output=True)
        if "exists" == result.stdout.decode('utf-8').strip():
            break
        else:
            print(f'waiting for the file {remote_file_path} to be created on the remote server.')
        time.sleep(poll_interval)


def kill_tmux_session(
        session_name, remote_file_path,
        username="iory", bastion_username="iory", bastion_ip="dlbox2.jsk.imi.i.u-tokyo.ac.jp",
        output_ip="", output_username="", ip='133.11.216.78',
        identity_file=osp.join(osp.expanduser('~'), '.ssh', 'id_rsa'),
):
    proxy_command = "ssh -i {} -o ProxyCommand='ssh -i {} -W %h:%p {}@{}'".format(
        identity_file, identity_file, bastion_username, bastion_ip)
    '{}@{}'.format(username, ip)
    ssh_command = "{} -i {} {}@{}".format(proxy_command, identity_file, username, ip)

    run_command(ssh_command + ' ' + ' '.join(["tmux", "kill-session", '-t', session_name]), shell=True)


def train_in_remote(
        image_directory='/home/iory/src/github.com/jsk-ros-pkg/jsk_demos/train/yamagata_items',
        bastion_username = 'iory',
        bastion_ip = 'dlbox2.jsk.imi.i.u-tokyo.ac.jp',
        username = 'iory',
        ip = '133.11.216.78',
        output='',
        output_ip='',
        output_username='',
        identity_file=osp.join(osp.expanduser('~'), '.ssh', 'id_rsa')):
    source_image_dir_in_remote, session_name = run_ssh_task(image_directory)
    remote_file_path = Path(source_image_dir_in_remote) / 'generated_data' / 'yolov7-seg-coco' / 'weights' / 'best.pt'

    watchdog(bastion_username, bastion_ip, username, ip, remote_file_path,
             identity_filepath=identity_file)
    kill_tmux_session(session_name, remote_file_path, identity_file=identity_file)

    output_to_remote = False
    if len(output_ip) > 0 and len(output_username) > 0:
        tmp_output = tempfile.TemporaryDirectory()
        makedirs(osp.join(tmp_output.name, osp.dirname(output)))
        output_to_remote_filename_pairs = []
        output_to_remote = True

    if output_to_remote is False and len(output) > 0:
        output = output.rstrip('/')
        makedirs(osp.dirname(output))

    if len(output) > 0:
        if output_to_remote:
            saved_weight_name = osp.join(tmp_output.name, '{}.pt'.format(output))
            output_to_remote_filename_pairs.append(
                (saved_weight_name, '{}.pt'.format(output)))
        else:
            saved_weight_name = '{}.pt'.format(output)
    else:
        saved_weight_name = './{}-{}.pt'.format(osp.basename(source_image_dir), date)

    ssh_target = '{}@{}'.format(username, ip)
    proxy_command = "ssh -i {} -o ProxyCommand='ssh -i {} -W %h:%p {}@{}'".format(
        identity_file, identity_file, bastion_username, bastion_ip)
    rsync_image_command = 'rsync -e "{}" --verbose {}:{} {}'.format(
        proxy_command,
        ssh_target, '{}/generated_data/yolov7-seg-coco/weights/best.pt'.format(source_image_dir_in_remote),
        saved_weight_name)
    run_command(rsync_image_command, shell=True)

    if len(output) > 0:
        if output_to_remote:
            saved_yaml_name = osp.join(tmp_output.name, '{}.yaml'.format(output))
            output_to_remote_filename_pairs.append(
                (saved_yaml_name, '{}.yaml'.format(output)))
        else:
            saved_yaml_name = '{}.yaml'.format(output)
    else:
        saved_yaml_name = './{}-{}.yaml'.format(osp.basename(source_image_dir), date)
    rsync_image_command = 'rsync -e "{}" --verbose {}:{} {}'.format(
        proxy_command,
        ssh_target, '{}/generated_data/from_images_dir.yaml'.format(source_image_dir_in_remote),
        saved_yaml_name)
    run_command(rsync_image_command, shell=True)

    return saved_weight_name, saved_yaml_name


if __name__ == '__main__':
    from eos import measure
    with measure():
        filename = '{}.pt'.format(current_time_str())
        saved_weight_filepath, saved_yaml_name = train_in_remote(
            image_directory='/home/iory/Downloads/2023-09-19/backupdata',
            output=osp.join(osp.expanduser('~'), 'dataset', '2023-09-21', filename))
