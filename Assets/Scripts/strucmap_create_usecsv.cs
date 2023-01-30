using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using System.IO;
using System.Text;
using System.Numerics;
using System.Collections.Generic;
using UnityEditor;

public class strucmap_create_usecsv : MonoBehaviour
{
    static public int size=64;//LUTのサイズ


    public double[,,,] strucTable = new double[size,size,size,3];//縦、横、色(*3しているのはRGBあるため)

    void Start()
    {
        //まず, pythonプログラムで生成したcsvファイルがAssets/Scripts/LUT_Csvs/フォルダにあることを確認してください. 
        //そしたらそのcsvのファイル名を, input_csvfilenameに代入してください. 
        //output_csvfilenameには, 出力する３Dテクスチャのファイル名を入力してください. 

        string input_csvfilename="strucmap0_400_D93_Air_1.34_Air_64_wide.csv";//入力するcsvファイルのファイル名
        string output_3dtexfilename="strucmap0_400_D93_Air_1.34_Air_64_wide.asset";//出力するtexture3Dのファイル名


        Texture3D Output_3DTexture;
        readfile(input_csvfilename);
        //Debug.Log(Refl1(30,1,1.5,1.6,200,20));
        Output_3DTexture=create_3dtex();
        AssetDatabase.CreateAsset(Output_3DTexture, "Assets/LUTs/"+output_3dtexfilename);//変える
        
    }
    

    void readfile(string input)
    {//csvデータを配列に格納
        string filePath_1=@"Assets/LUT_Csvs/"+input;
        StreamReader reader = new StreamReader(filePath_1, Encoding.GetEncoding("UTF-8"));

        int count=0;
        int zdep=0;
        string vol;
        while (reader.Peek() >= 0)
        {
            string[] cols = reader.ReadLine().Split(',');
            for(int i=0;i<size*3;i++){
                vol=cols[i];
                if(vol=="nan"){
                    vol="0";
                }
                float a=float.Parse(vol);
                strucTable[i/3,count,zdep,i%3]=a/255;//正規化
            }
            count++;
            //
            if(count==size){
                count=0;
                zdep++;
            }
        }
        reader.Close();
    }
    
    Texture3D create_3dtex(){//strucTableに格納したデータを3DTextureにする

        Texture3D Output_3DTexture;
        Color[] colorArray = new Color[size * size * size];
        Output_3DTexture = new Texture3D (size, size, size, TextureFormat.RGBA32, true);
        //float r = 1.0f / (size-1.0f);
        for (int x = 0; x < size; x++) {
            for (int y = 0; y < size; y++) {
                for (int z = 0; z < size; z++) {
                    float B=(float)strucTable[x,y,z,0];
                    float G=(float)strucTable[x,y,z,1];
                    float R=(float)strucTable[x,y,z,2];
                    Color color = new Color (R, G, B, 1.0f);
                    colorArray[x + (y * size) + (z * size * size)] = color;
                }
            }
        }
        //3Dテクスチャ化する
        Output_3DTexture.SetPixels (colorArray);
        Output_3DTexture.Apply ();
        return Output_3DTexture;
    }
    
}
