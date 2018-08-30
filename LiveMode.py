from __future__ import print_function
import math
import binascii
import csv
import sys
import time
import cantools
from panda import Panda
import matplotlib.pyplot as plt
import matplotlib.animation as animation
from matplotlib import style
from drawnow import *

array1 = []
arrayTime = []

def animate():
  global array1
  plt.title('Live Mode')
  plt.plot(array1)  

def LiveMode(input1,input2):
  global array1
  global arrayTime
  plt.ion()  
  style.use('fivethirtyeight')
  fig = plt.figure()
  ax1 = fig.add_subplot(1,1,1)
  try:
    print("Trying to connect to Panda over USB...")
    p = Panda()
  except AssertionError:
    print("USB connection failed...")
    sys.exit(0)
  db = cantools.database.load_file('C:\Users\DellPC\Desktop\panda\examples\CivicDBC.dbc')
  myMsg = db.get_message_by_name(input1)
  for i in range(len(myMsg.signals)):
    if myMsg.signals[i].name == input2:
      I = i
      mySig = myMsg.signals[I]
      BitStart = int(mySig.start)
      BitLength = int(mySig.length)
      BitNum = int(myMsg.length)*8
      BitSign = bool(mySig.is_signed)
      BitScale = int(mySig.scale)
      BitOffset = int(mySig.offset)
      BitMinimum = int(mySig.minimum)
      BitMaximum = int(mySig.maximum)
      MSB = int((7 - (BitStart % 8)) + (8 * (math.floor(BitStart/8)))) 
      break;
  try:
    outputfile = open('output.csv', 'wb')
    csvwriter = csv.writer(outputfile)
    csvwriter.writerow(['Bus', 'MessageID', 'Message', 'MessageLength', 'Time'])
    print("Writing csv file output.csv. Press Ctrl-C to exit...\n")
    bus0_msg_cnt = 0
    bus1_msg_cnt = 0
    bus2_msg_cnt = 0
    arraylen = 0
    output1 = 0
    while True:
      can_recv = p.can_recv()
      for address, _, dat, src  in can_recv:
        csvwriter.writerow([str(src), str(hex(address)).rstrip("L"), "0x" + binascii.hexlify(dat), len(dat), time.clock(), output1])
        if address == myMsg.frame_id:
          if arraylen >= 150:
            array1 = array1[1:]
            arrayTime = arrayTime[1:]
            arraylen -= 1
          arraylen += 1 
          arrayTime.append(time.clock())
          binX = bin(int(binascii.hexlify(dat), 16))[2:].zfill(BitNum)
          # print(binX)
          # print(MSB)
          # print(MSB+BitLength)
          # print(len(binX))
          # print(BitNum)
          output1 = int(binX[MSB:MSB+BitLength],2)
          if BitSign and binX[MSB] == 1:
            output1 = output1 * -1 + 1
          output1 = output1 * BitScale + BitOffset
          if output1 >= BitMaximum or output1 <= BitMinimum:
            array1.append(0)
          else:
            array1.append(output1)
          # array1.append(output1)
          drawnow(animate)
          plt.pause(0.000001)
        if src == 0:
          bus0_msg_cnt += 1
        elif src == 1:
          bus1_msg_cnt += 1
        elif src == 2:
          bus2_msg_cnt += 1
        # print("Message Counts... Bus 0: " + str(bus0_msg_cnt) + " Bus 1: " + str(bus1_msg_cnt) + " Bus 2: " + str(bus2_msg_cnt), end='\r')

  except KeyboardInterrupt:
    print("\nNow exiting. Final message Counts... Bus 0: " + str(bus0_msg_cnt) + " Bus 1: " + str(bus1_msg_cnt) + " Bus 2: " + str(bus2_msg_cnt))
    outputfile.close()

if __name__ == "__main__":
  input1 = input(" Enter the ECU: \n")
  input2 = input(" Enter the subcomponent: \n")
  LiveMode(input1,input2)

