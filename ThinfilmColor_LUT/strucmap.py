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

 # C S V ファイルを読み込み, 配列に格納する
def csv_read(file):
  csvfile=open(file,'StrucColor_Reflectance',encoding='utf-8')
  reader=csv.reader(csvfile)
  ColorMatchingFunction = []
  ColorMatchingFunction2 = []
  for row in reader:
    ColorMatchingFunction.append(row)
  csvfile.close()
  for row in ColorMatchingFunction:
    ColorMatchingFunction2.append([float(n) if n!='\ufeff390' else lmdmin for n in row])
  return np.array(ColorMatchingFunction2)

def csv_write(LUT_string, path, Min_FilmThickness, Max_FilmThickness, ColorTemperature, RefractiveIndex, ColorSpace):
  with open(path+str(Min_FilmThickness)+"_"+str(Max_FilmThickness)+"_"+str(ColorTemperature[:-4])+"_Air_"+str(RefractiveIndex)+"_Air"+"_64_"+str(ColorSpace)+".csv",mode='w') as file:
    file.write(LUT_string)



ColorMatchingFunction = csv_read('lin2012xyz2e_5_7sf.csv')



class StrucColor:#入射角と反射角と膜厚と屈折率と色空間と色温度
  def __init__(self, IncidenceAngle,FilmThickness,ReflectionAngle,n2,ColorSpace,ColorTemperature):#コンストラクタ
    self.n1 = 1.0 # 1層目の屈折率
    self.n2 = n2 # 2層目の屈折率(石鹸水)
    self.n3=1.0
    self.IncidenceAngle = float(IncidenceAngle)
    self.FilmThickness=float(FilmThickness)
    self.ReflectionAngle=float(ReflectionAngle)
    self.ColorTemperature = csv_read(ColorTemperature)
    self.ColorSpace=ColorSpace
    self.Calc_StrucColor()
    
  def Calc_Reflectance(self,wavelength):#構造色反射率を導出する関数
    #入射角
    IncidenceAngle_Radian=np.radians(self.IncidenceAngle)
    IncidenceAngle_Cos=np.cos(IncidenceAngle_Radian)
    IncidenceAngle_Sin=np.sin(IncidenceAngle_Radian)

    #反射角
    n1n2_ReflectionAngle_Radian=np.radians(self.ReflectionAngle)

    #屈折角
    n1n2_RefractionAngle_Radian=np.arcsin(np.sin(IncidenceAngle_Radian)*self.n1 / self.n2)
    n2n3_RefractionAngle_Radian=np.arcsin(np.sin(n1n2_RefractionAngle_Radian)*self.n2 / self.n3)
    n1n2_RefractionAngle_Cos=np.cos(n1n2_RefractionAngle_Radian)
    n2n3_RefractionAngle_Cos=np.cos(n2n3_RefractionAngle_Radian)

    # フレネル反射率の計算
    n1n2_FresnelReflectance_Spolarized = (self.n1 * IncidenceAngle_Cos - self.n2 * n1n2_RefractionAngle_Cos) / (self.n1 * IncidenceAngle_Cos +self.n2 * n1n2_RefractionAngle_Cos)
    n1n2_FresnelReflectance_Ppolarized = (self.n2 * IncidenceAngle_Cos - self.n1 * n1n2_RefractionAngle_Cos) / (self.n2 * IncidenceAngle_Cos + self.n1 * n1n2_RefractionAngle_Cos)
    n2n3_FresnelReflectance_Spolarized = (self.n2 * n1n2_RefractionAngle_Cos - self.n3 * n2n3_RefractionAngle_Cos) / (self.n2 * n1n2_RefractionAngle_Cos + self.n3 * n2n3_RefractionAngle_Cos)
    n2n3_FresnelReflectance_Ppolarized = (self.n3 * n1n2_RefractionAngle_Cos - self.n2 * n2n3_RefractionAngle_Cos) / (self.n3 * n1n2_RefractionAngle_Cos + self.n2 * n2n3_RefractionAngle_Cos)
    n2n1_FresnelReflectance_Spolarized = (self.n2 * n1n2_RefractionAngle_Cos-self.n1 * IncidenceAngle_Cos) / (self.n2 * n1n2_RefractionAngle_Cos+self.n1 * IncidenceAngle_Cos)
    n2n1_FresnelReflectance_Ppolarized = (self.n1 * n1n2_RefractionAngle_Cos-self.n2 * IncidenceAngle_Cos) / (self.n1 * n1n2_RefractionAngle_Cos+self.n2 * IncidenceAngle_Cos)
    n2n1_FresnelReflectance=(n1n2_FresnelReflectance_Spolarized+n1n2_FresnelReflectance_Ppolarized)*0.5
    n2n3_FresnelReflectance=(n2n3_FresnelReflectance_Spolarized+n1n2_FresnelReflectance_Ppolarized)*0.5
    n2n1_FresnelReflectance=(n2n1_FresnelReflectance_Spolarized+n2n1_FresnelReflectance_Ppolarized)*0.5

    #フレネル透過率の計算
    n1n2_FresnelTransmittance_Spolarized=2*self.n1*IncidenceAngle_Cos/(self.n1*IncidenceAngle_Cos+self.n2*n1n2_RefractionAngle_Cos)
    n1n2_FresnelTransmittance_Ppolarized=2*self.n1*IncidenceAngle_Cos/(self.n1*n1n2_RefractionAngle_Cos+self.n2*IncidenceAngle_Cos)
    n2n1_FresnelTransmittance_Spolarized=2*self.n2*n1n2_RefractionAngle_Cos/(self.n2*n1n2_RefractionAngle_Cos+self.n1*IncidenceAngle_Cos)
    n2n1_FresnelTransmittance_Ppolarized=2*self.n2*n1n2_RefractionAngle_Cos/(self.n2*IncidenceAngle_Cos+self.n1*n1n2_RefractionAngle_Cos)
    n1n2_FresnelTransmittance=(n1n2_FresnelTransmittance_Spolarized+n1n2_FresnelTransmittance_Ppolarized)*0.5
    n2n1_FresnelTransmittance=(n2n1_FresnelTransmittance_Spolarized+n2n1_FresnelTransmittance_Ppolarized)*0.5

    #光路差の計算
    n1n2_RefractionAngle_Tan=np.tan(n1n2_RefractionAngle_Radian)
    n2n3_ReflectionAngle_Sin = np.sin(n1n2_ReflectionAngle_Radian) / self.n2
    n2n3_ReflectionAngle_Radian = np.arcsin(n2n3_ReflectionAngle_Sin)
    n2n3_ReflectionAngle_Cos=np.cos(n2n3_ReflectionAngle_Radian)
    n2n3_ReflectionAngle_Tan=np.tan(n2n3_ReflectionAngle_Radian)
    Optical_Path_Difference=self.n2*self.FilmThickness*(1/n1n2_RefractionAngle_Cos+1/n2n3_ReflectionAngle_Cos)-self.n1*self.FilmThickness*(n1n2_RefractionAngle_Tan+n2n3_ReflectionAngle_Tan)*IncidenceAngle_Sin#異角度光路差
    
    #構造色反射率の計算
    Phase_Difference = (2.0 * np.pi * Optical_Path_Difference) / wavelength
    StrucColor_Reflectance=np.square(np.abs(n2n1_FresnelReflectance+n1n2_FresnelTransmittance*n2n1_FresnelTransmittance*n2n3_FresnelReflectance*np.exp(1j*Phase_Difference)/(1-n2n3_FresnelReflectance*n2n1_FresnelReflectance*np.exp(1j*Phase_Difference))))
    return StrucColor_Reflectance

  def Calc_StrucColor(self):
    wavelengths = ColorMatchingFunction[:, 0]
    xyz = np.zeros(3)

    StrucColor_Reflectance=self.Calc_Reflectance(wavelengths)

    # 反射率を, XYZ色空間に変換
    xyz[0] = integrate.simps(StrucColor_Reflectance * ColorMatchingFunction[:,1] * self.ColorTemperature[:,1], wavelengths)
    xyz[1] = integrate.simps(StrucColor_Reflectance * ColorMatchingFunction[:,2] * self.ColorTemperature[:,1], wavelengths)
    xyz[2] = integrate.simps(StrucColor_Reflectance * ColorMatchingFunction[:,3] * self.ColorTemperature[:,1], wavelengths)
    k = integrate.simps(ColorMatchingFunction[:,2] * self.ColorTemperature[:,1], wavelengths)
    xyz *= 1/k

    # XYZ色空間を, RGB座標に変換
    if self.ColorSpace=="srgb":
      self.xyz_to_srgb(xyz)
    elif self.ColorSpace=="wide":
      self.xyz_to_widegamut(xyz)
    
  def xyz_to_srgb(self, xyz):
    trans_matrix=np.array([[3.240970,-1.537383,-0.498611],[-0.969244,1.875968,0.041555],[0.055630,-0.203977,1.056972]])
    rgb=np.dot(trans_matrix,xyz)
    rgb[rgb > 1] = 1
    rgb[rgb < 0] = 0
    self.rgb = rgb * 255
      
  def xyz_to_widegamut(self, xyz):
    trans_matrix=np.array([[1.4625,-0.1845,-0.2734],[-0.5228,1.4479,0.0681],[0.0346,-0.0958,1.2875]])
    rgb=np.dot(trans_matrix,xyz)

    rgb[rgb > 1] = 1
    rgb[rgb < 0] = 0
    self.rgb = rgb * 255

    
    


def main():#屈折率, 色空間, 色温度で複数のLUTを出力
  Max_IncidenceAngle = 90#度数法表記. 0度～Max_incidence度の入射角範囲でLUT生成
  Max_ReflectionAngle=90#度数法表記. 0度～Max_ReflectionAngle度の反射角範囲でLUT生成
  Min_FilmThickness=0#単位:nm
  Max_FilmThickness=400#単位:nm
  Range_FilmThickness = Max_FilmThickness-Min_FilmThickness
  
  LUT_size=64#LUT_size*LUT_size*LUT_sizeのLUTを生成
  RefractiveIndexes=[1.34]#1.34:石鹸水の屈折率
  ColorSpaces=["srgb","wide"]
  ColorTemperatures=['D65.csv','D55.csv','D93.csv']
  Complete_LUT_Count=1

  #LUTをlen(RefractiveIndexes)*len(ColorSpaces)*len(ColorTemperatures)個作成
  for RefractiveIndex in RefractiveIndexes:
    for ColorSpace in ColorSpaces:
      for ColorTemperature in ColorTemperatures:
        LUT_string=''
        #以下で1つのLUTを作成
        for ReflectionAngle in range(LUT_size):
          for IncidenceAngle in range(LUT_size):
            for FilmThickness in range(LUT_size):
              color = StrucColor(IncidenceAngle*Max_IncidenceAngle/(LUT_size-1),Min_FilmThickness+FilmThickness*Range_FilmThickness/(LUT_size-1),ReflectionAngle*Max_ReflectionAngle/(LUT_size-1),RefractiveIndex,ColorSpace,ColorTemperature)#立方体用に調整
              Col = [color.rgb[0], color.rgb[1], color.rgb[2]]
              for c in range(3):
                LUT_string+=str(Col[c])
                if FilmThickness==Max_FilmThickness and c==2:
                  pass
                else:
                  LUT_string+=","
            LUT_string+="\n"
        csv_write(LUT_string,"..\Assets\LUT_Csvs\strucmap", Min_FilmThickness, Max_FilmThickness, ColorTemperature, RefractiveIndex, ColorSpace)
        print(Complete_LUT_Count)#LUTが何個完成したかをコンソールアウト
        Complete_LUT_Count+=1



if __name__ == '__main__':
  main()