import socket

def main():
    """main"""
    print pdp()
    print sts()

def pdp(host="172.16.174.205", port=9000, timeout=3):

    try:
        socket.setdefaulttimeout(timeout)
        socket.socket(socket.AF_INET, socket.SOCK_STREAM).connect((host, port))
        return True
    except Exception as ex:
        print ex.message
        return False

def sts(host="172.16.174.203", port=7003, timeout=3):

    try:
        socket.setdefaulttimeout(timeout)
        socket.socket(socket.AF_INET, socket.SOCK_STREAM).connect((host, port))
        return True
    except Exception as ex:
        print ex.message
        return False

if __name__ == '__main__':
    main()