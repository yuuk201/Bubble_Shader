import numpy as np
from scipy import integrate
from scipy.signal import convolve2d
from matplotlib import pyplot as plt  
import cv2
#import colour
import csv
import colour
import time
from PIL import Image
lmdmin=390
class Csv_Color:
 # C S V ファイルを読み込み, 配列に格納する
  def csv_read(self, file):
    csvfile=open(file,'r',encoding='utf-8')
    reader=csv.reader(csvfile)
    cmf = []
    cmf2 = []
    for row in reader:
      cmf.append(row)
    csvfile.close()
    for row in cmf:
      cmf2.append([float(n) if n!='\ufeff390' else lmdmin for n in row])
    return np.array(cmf2)

cc =Csv_Color()
cmf = cc.csv_read('lin2012xyz2e_5_7sf.csv')



class ThinColor:#入射角と反射角と膜厚と屈折率と色空間と色温度

    def __init__(self, angle,d,refangle,n2,rgbspace,rgbK):#コンストラクタ
        self.n1 = 1.0 # 1層目の屈折率
        self.n2 = n2 # 2層目の屈折率(石鹸水)
        self.n3=1.0
        self.angle = float(angle)
        self.d=float(d)
        self.refangle=float(refangle)
        self.light_col = cc.csv_read(rgbK)
        self.rgbspace=rgbspace
        self.clc_st_color() #構造色を計算する

    def clc_st_color(self):
        wavelengths = cmf[:, 0]
        xyz = np.zeros(3)
        I = integrate.simps(cmf[:, 2], wavelengths)
        # wavelengthsの範囲で積分し, 反射率からx y z 表色系に変換する
        xyz[0] = integrate.simps(self.f(wavelengths, 1), wavelengths)
        xyz[1] = integrate.simps(self.f(wavelengths, 2), wavelengths)
        xyz[2] = integrate.simps(self.f(wavelengths, 3), wavelengths)
        kk = integrate.simps(self.f2(wavelengths, 2), wavelengths)
        k = 1 / kk
        xyz *= k
        if self.rgbspace=="srgb":
          self.xyz_to_srgb(xyz)
        elif self.rgbspace=="wide":
          self.xyz_to_widegamut(xyz)
    def xyz_to_srgb(self, xyz):
        trans_matrix=np.array([[3.240970,-1.537383,-0.498611],[-0.969244,1.875968,0.041555],[0.055630,-0.203977,1.056972]])
        rgb=np.dot(trans_matrix,xyz)

        """
        for i in range(3):
          if rgb[i]<=0.0031308:
            rgb[i]*=12.92
          elif rgb[i]>0.0031308:
            rgb[i]=1.055*np.power(rgb[i],1/2.4)-0.055
        """

    
        rgb[rgb > 1] = 1
        rgb[rgb < 0] = 0
        self.rgb = rgb * 255
    def xyz_to_widegamut(self, xyz):
        trans_matrix=np.array([[1.4625,-0.1845,-0.2734],[-0.5228,1.4479,0.0681],[0.0346,-0.0958,1.2875]])
        rgb=np.dot(trans_matrix,xyz)
        """
        for i in range(3):
          if rgb[i]<=0.0031308:
            rgb[i]*=12.92
          elif rgb[i]>0.0031308:
            rgb[i]=1.055*np.power(rgb[i],1/2.4)-0.055
        """

        rgb[rgb > 1] = 1
        rgb[rgb < 0] = 0
        self.rgb = rgb * 255

    def f(self, wavelengths, index):
        #r = self.BRDF(wavelengths) # 薄膜干渉の反射率を求める
        r=self.clc_reflectance(wavelengths)
        col = r * cmf[:,index] * self.light_col[:,1]
        return col

    def f2(self, wavelengths, index):
        col = cmf[:,index] * self.light_col[:,1]
        return col
    def clc_reflectance(self,wavelength):
        rad = np.radians(self.angle)
        refrad=np.radians(self.refangle)
        cos1 = np.cos(rad)#入射角コサイン
        sin01=np.sin(rad)#入射角サイン
        sin2 = np.sin(rad)*self.n1 / self.n2
        rad2 = np.arcsin(sin2)#入射角の屈折角
        cos2 = np.cos(rad2)
        cos3 = cos1
        tan1=np.tan(rad2)#入射角の屈折角のタンジェント
        cos0=np.cos(refrad)#反射角コサイン
        sin00=np.sin(refrad)#反射角サイン
        sin0 = np.sin(refrad) / self.n2
        rad0 = np.arcsin(sin0)#反射角の屈折角
        cos4=np.cos(rad0)#反射角の屈折角のコサイン
        tan2=np.tan(rad0)#反射角の屈折角のタンジェント
# 以下フレネル係数
        rs12 = (self.n1 * cos1 - self.n2 * cos2) / (self.n1 * cos1 +self.n2 * cos2)
        rp12 = (self.n2 * cos1 - self.n1 * cos2) / (self.n2 * cos1 + self.n1 * cos2)
        rs23 = (self.n2 * cos2 - self.n3 * cos3) / (self.n2 * cos2 + self.n3 * cos3)
        rp23 = (self.n3 * cos2 - self.n2 * cos3) / (self.n3 * cos2 + self.n2 * cos3)
        r12=(rs12+rp12)*0.5
        r23=(rs23+rp23)*0.5
        r21=1-r12
        t12=1-r12
        t21=r12

        
        delta=self.n2*self.d*(1/cos2+1/cos4)-self.n1*self.d*(tan1+tan2)*sin01#異角度光路差
        phi = (2.0 * np.pi * delta) / wavelength # 位相差
        rrs = (np.square(rs12 + rs23 * np.cos(phi)) + np.square(rs23 * np.sin(phi))) / (np.square(1 + rs23 * rs12 * np.cos(phi)) + np.square(rs23 * rs12* np.sin(phi)))
        rrp = (np.square(rp12 + rp23 * np.cos(phi)) + np.square(rp23 * np.sin(phi))) / (np.square(1 + rp23 * rp12 * np.cos(phi)) + np.square(rp23 * rp12* np.sin(phi)))
        rr = np.abs((rrs + rrp) *0.5)
        return rr


def main():#屈折率, 色空間, 色温度で複数のLUTを出力
  width = 90#入射角(横軸)
  dmin=0#膜厚min(縦軸)
  dmax=400#膜厚max(縦軸)
  height = dmax-dmin
  depth=90#反射角(奥行)
  size=64#LUTのサイズ
  st=''
  n2s=[1.34]#石鹸水の屈折率
  rgbspaces=["srgb","wide"]
  rgbKs=['D65.csv','D55.csv','D93.csv']
  #writefile2='LUT_CSVs\18typesTexture\bubbles\strucmap0_400_difangle_d65_Air_Glass_Fe3O4_64_widegamut'
  count=1
  for n2 in n2s:
    for rgbspace in rgbspaces:
      for rgbK in rgbKs:
        st=''
        for refangle in range(size):
          for angle in range(size):
            for d in range(size):
              #reftangle=90
              color = ThinColor(angle*width/(size-1),d*dmax/(size-1),refangle*depth/(size-1),n2,rgbspace,rgbK)#立方体用に調整
              Col = [color.rgb[0], color.rgb[1], color.rgb[2]]
              for c in range(3):
                st+=str(Col[c])
                if d==dmax and c==2:
                  pass
                else:
                  st+=","
            st+="\n"
        with open("..\Assets\LUT_Csvs\strucmap"+str(dmin)+"_"+str(dmax)+"_"+str(rgbK[:-4])+"_Air_"+str(n2)+"_Air"+"_64_"+str(rgbspace)+".csv",mode='w') as file:
          file.write(st)
        print(count)#何個完成したかをコンソールアウト
        count+=1



if __name__ == '__main__':
    main()