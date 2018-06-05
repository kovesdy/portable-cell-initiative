import socket

host = "127.0.0.1"
port = 5039
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((host,port))
s.sendall("%%>connect:global:%%n")
s.sendall(b"%%>output:Successfully connected python controller")

s.sendall(b"%%>watch:msg.execute")
s.sendall(b"%fclose\n")
confirmation = s.recv(1024)
print('Confirmation: ' + confirmation)

data = s.recv(1024)

s.close()
print('Received', data)
