import cv2
import numpy as np
import socket

FPS = 30
# Create the server
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

server_address = ("127.0.0.1", 3000)
sock.bind(server_address)

sock.listen()

print("Waiting for connection")

conn, addr = sock.accept()

def policy(img):
    # Find the ball position
    ball_mask = cv2.inRange(img, np.array([0, 0, 200]), np.array([0,0,255]))
    stats = cv2.connectedComponentsWithStats(ball_mask)
    ball_position = stats[3][1]

    bat_mask = cv2.inRange(img, np.array([200, 0, 0]), np.array([255,0,0]))
    stats = cv2.connectedComponentsWithStats(bat_mask)
    bat_position = stats[3][1]
    disc = np.cross(bat_position-[50,50], ball_position-[50,50])
    #cv2.imshow("ball_mask", bat_mask)
    #cv2.waitKey(1)
    # Find the bat position
    if disc < 0:
        return -1
    if disc > 0:
        return 1
    return 0


while True:
    protocol_id = int.from_bytes(conn.recv(4),'little')
    if protocol_id == 0: # Define input protocol id as 0 for video stream
        img_len = int.from_bytes(conn.recv(4), 'little') # Compressed image length
        img_data = b""
        while len(img_data) < img_len:
            img_data = img_data + conn.recv(img_len - len(img_data))
        img = cv2.imdecode(np.frombuffer(img_data, dtype=np.uint8), cv2.IMREAD_UNCHANGED)
        cv2.imshow("output", img)
        command = policy(img)
        conn.sendall(int.to_bytes(1, 4, 'little')) # Define output protocol id as 1 for action
        conn.sendall(int.to_bytes(command, 4, 'little', signed=True))
        key = cv2.waitKey(1) & 0xFF
        if key in [ord('q'), 27]:
            break
    else:
        print("Unknown protocol id!")
        break

sock.close()