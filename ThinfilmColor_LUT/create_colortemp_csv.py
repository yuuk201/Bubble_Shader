import numpy as np
import matplotlib.pyplot as plt

lmdmin=390
lmdmax=780

#illuminantDの計算で使うs0,s1,s2の分光分布の入力 300-830nm 10nm step
s0 = np.array([[65.8,94.8,104.8,105.9,96.8,113.9,125.6,125.5,121.3,121.3,113.5,113.1,110.8,106.5,108.8,105.3,104.4,100,96,95.1,89.1,90.5,90.3,88.4,84,85.1,81.9,82.6,84.9,81.3,71.9,74.3,76.4,63.3,71.7,77,65.2,47.7,68.6,65,66,61,53.3,58.9,61.9]])
s1 = np.array([[35,43.4,46.3,43.9,37.1,36.7,35.9,32.6,27.9,24.3,20.1,16.2,13.2,8.6,6.1,4.2,1.9,0,-1.6,-3.5,-3.5,-5.8,-7.2,-8.6,-9.5,-10.9,-10.7,-12,-14,-13.6,-12,-13.3,-12.9,-10.6,-11.6,-12.2,-10.2,-7.8,-11.2,-10.4,-10.6,-9.7,-8.3,-9.3,-9.8]])
s2 = np.array([[1.2,-1.1,-0.5,-0.7,-1.2,-2.6,-2.9,-2.8,-2.6,-2.6,-1.8,-1.5,-1.3,-1.2,-1,-0.5,-0.3,0,0.2,0.5,2.1,3.2,4.1,4.7,5.1,6.7,7.3,8.6,9.8,10.2,8.3,9.6,8.5,7,7.6,8,6.7,5.2,7.4,6.8,7,6.4,5.5,6.1,6.5]])
Vaxis = np.array(range(lmdmin, lmdmax, 10))
#色温度を指定してD光源の分光分布を合成
def calcIlluminantD(temperature):#10nmのステップで格納
    T = temperature
    xd = 0.0
    if (4000<= T and T<=7000):
        xd = 0.244063+0.09911*10**3/T + 2.9678*10**6/(T**2)-4.6070*10**9/(T**3)
    elif  (7000<= T and T<=25000):
        xd = 0.237040+0.24748*10**3/T + 1.9018*10**6/(T**2)-2.0064*10**9/(T**3)
    yd = -3.0*xd**2 + 2.87*xd -0.275
    m = 0.0241+0.2562*xd-0.7341*yd
    m1 = (-1.3515-1.7703*xd+5.9114*yd)/m
    m2 = (0.03-31.4424*xd+30.0717*yd)/m
    sd = s0 + s1*m1 + s2*m2
    return (sd.reshape(45))

def interpolation(sd):#10nmごとに入っているilluminantDのスペクトルを, 補間して1nmごとにする. 
  sd_new=[]
  for i in range(int((lmdmax-lmdmin)/10)):
    sd_new.append(sd[i])
    for j in range(9):
      aida=(sd[i+1]-sd[i])/10#間隔の値
      sd_new.append(sd[i]+aida*(j+1))
  sd_new.append(sd[int((lmdmax-lmdmin)/10)])
  return sd_new

def create_csv(f,arr):
  st=""
  for i in range(lmdmin, lmdmax+1):
    st+=str(i)+","+str(arr[i-lmdmin])+"\n"
  with open(f,mode='w') as file:
    file.write(st)



def create_colortemp_csv(f, temperature):
  sd=calcIlluminantD(temperature)
  sd_new=interpolation(sd)
  create_csv(f,sd_new)

f="D93.csv"
temperature=9300
create_colortemp_csv(f,temperature)