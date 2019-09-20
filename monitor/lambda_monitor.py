import socket
import requests

hostname = '[hostname:%s lambda_missed_blocks_alarm]' % socket.gethostname()

def_headers = {'Content-Type': 'application/json'}
def_timeout = 30
miss_block_alarm_num = 0

token = ""
show_validator = ""


def post(url, headers=def_headers, timeout=def_timeout, data=None, proxies=None):
    response = requests.post(url, data=data, headers=headers, timeout=timeout, proxies=proxies)
    if response.status_code / 200 != 1:
        raise Exception(response.text)
    return response


def get(url, headers=def_headers, timeout=def_timeout, params=None, proxies=None):
    response = requests.get(url, params=params, headers=headers, timeout=timeout, proxies=proxies)
    if response.status_code / 200 != 1:
        raise Exception(response.text)
    return response


class DingTalk:
    @staticmethod
    def ding_talk_notify(message, token):
        if token is None or token is "":
            return
        try:
            ding_talk_hook_url = "https://oapi.dingtalk.com/robot/send?access_token=" + token
            body = ('{"msgtype":"text","text":{"content":"%s"}}' % message)
            post(ding_talk_hook_url, data=body)
        except Exception as e:
            print("dingTalk notify error, msg:%s, exception:%s", message, e)


class Notify:
    @staticmethod
    def notify_status(*args):
        Notify.all_notify(False, *args)

    @staticmethod
    def notify_error(*args):
        Notify.all_notify(True, *args)

    @staticmethod
    def all_notify(is_error, *args):
        # add other like slack, sms...
        if args is None or len(args) < 1:
            return
        msg = '\n'.join(args)
        if is_error:
            DingTalk.ding_talk_notify(msg, token)
        else:
            DingTalk.ding_talk_notify(msg, token)


def miss_block_waring(miss_block_alarm_num):
    url = "http://39.107.247.86:13659/slashing/validators/%s/signing_info" % show_validator
    ret = get(url).json()
    if not ret:
        msg = ("call validators signing_info get failed:%s" % ret)
        Notify.notify_error(hostname, msg)
        return

    miss_counter = int(ret["missed_blocks_counter"])
    if miss_counter >= miss_block_alarm_num:
        msg = ("miss_block_alarm_num:%s,remote_missed_blocks_counter:%s" % (miss_block_alarm_num, miss_counter))
        Notify.notify_error(hostname, msg)


if __name__ == '__main__':
    miss_block_waring(miss_block_alarm_num)
