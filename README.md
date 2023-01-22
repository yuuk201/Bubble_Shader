# Bubble_Shader

![bubble](https://user-images.githubusercontent.com/56100173/213690641-aac9328d-3594-4668-b459-e23123d66185.jpg)

## 実行環境
2021.1.13f1

## 起動方法
ダウンロードし, Unityを起動させ, Assets\ScenesにあるBubbleSceneを立ち上げるとシャボン玉があるシーンを見ることができる. このシャボン玉の色はpythonプログラムで事前に計算し, それを3DTextureの形式で出力し, それをシェーダプログラムに入力することで色を出している. 3Dtexture生成プログラムの説明は, 後ほど記す. 

## 薄膜による構造色とは
シャボン玉は表面が薄膜になっており, 光が干渉しあう. 薄膜の厚さ(膜厚), 入射角, 反射角など多くのパラメータによって色が変わる. 入射角と反射角に依存して色が変わるため, 見る位置によって色が変わる. 



## Inspector
### Color Space
![colorspace](https://user-images.githubusercontent.com/56100173/173701285-c391e035-135b-499e-a975-2d6df365ca6e.JPG)

構造色ルックアップテーブルの色空間を指定する．色空間は，sRGBかwide gammutを選択できる. 
### Color Tempeture
![color temp](https://user-images.githubusercontent.com/56100173/173701212-df81084f-f051-442b-9bff-ff19cbb2b288.JPG)


光源の色温度を指定する. D光源の5500Kと6500Kと9300Kを選択することができる. 
### Rthinfilm material

![thinfilm material](https://user-images.githubusercontent.com/56100173/173701398-b4399026-1109-4d9f-a3a4-8f46de762df0.JPG)

薄膜の素材を選択できる。ここでは石鹸水であるsoapのみ選択可能
### Thinfilm(nm)
![thinfilm](https://user-images.githubusercontent.com/56100173/173701431-c7fe9c71-0676-478a-b3ea-881b15ecaa9f.JPG)

シャボン玉の膜厚の値



### Structual Color Alpha
![struc color alpha](https://user-images.githubusercontent.com/56100173/173701350-c1cd6aa5-6d9d-4f0f-9dc0-5176ec9c466b.JPG)

構造色とbasecolorテクスチャとのブレンド率を持つ. 

### Structural Color LT
![LUT](https://user-images.githubusercontent.com/56100173/173701477-e2902e1f-b6d5-431f-a911-e1976401f9df.JPG)


構造色のルックアップテーブル. 横軸を入射角(0°から90°), 縦軸を膜厚(0nmから400nm), 奥行を反射角(0°から90°)として, それぞれの値の色が格納されている. Unityの3DTextureを用いている. 

## 構造色を出すまでの流れ
![flow](https://user-images.githubusercontent.com/56100173/213839988-7dd91bf8-93d7-4df1-88be-39f21c49c04c.jpg)

本プログラムでの流れを上図に示す. 大まかな流れを説明する. まず, pythonプログラムを用いて構造色を事前計算する. 事前計算結果をルックアップテーブル(LUT)に格納する. そして, そのLUTのデータを参照する形で, Shaderプログラムが最終的な色を計算する. 以下に図で示しているプログラムファイルやLUTファイルの説明をする. 

### create_colortemp_csv.py
「hinfilmColor_LUT/」にあるプログラム. 
光源スペクトルを計算し, csv形式で出力するプログラム.

### strucmap.py
「hinfilmColor_LUT/」にあるプログラム. 構造色を計算し, その計算結果をcsv形式で出力するファイル. 具体的なアルゴリズムの説明はここでは省略するが, 薄膜干渉の構造色を物理的に計算している. このLUTは膜厚, 入射角, 反射角をパラメータとして色を格納している. 

### lin2012xyz2e_5_7sf.csv
x,y,zそれぞれの等色関数の値が入ったcsvファイル. 
https://zenodo.org/record/583697#.Y8tACXbP2Uk のデータを用いた. 

### strucmap_create_usecsv.cs
「Assets/Scripts/」にあるプログラム. csv形式のLUTを入力とし, Unityで扱えるTexture3D形式へと変換している. 

### bubbleProc_shader.shader
「Assets/Shader/」にあるプログラム. 最終的な色を計算しているシェーダープログラム. LUTを入力とし, 視点位置情報, 光源位置情報を用いて適切な色を取り出して出力している. 