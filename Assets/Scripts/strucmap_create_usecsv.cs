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
    // Start is called before the first frame update
    static public int dmin=400;//変える
    static public int dmax=800;//変える
    static public int height=dmax-dmin;
    static public int width=90;
    static public int depth=90;
    static public int size=64;

    void Start()
    {
        //まず, pythonプログラムで生成したcsvファイルがAssets/Scripts/LUT_Csvs/フォルダにあることを確認してください. 
        //そしたらそのcsvのファイル名を, input_csvfilenameに代入してください. 
        //output_csvfilenameには, 出力する３Dテクスチャのファイル名を入力してください. 
        //
        string input_csvfilename="strucmap400_800_D55_Air_1.34_Air_64_srgb.csv";//入力するcsvファイルのファイル名
        string output_3dtexfilename="strucmap400_800_D55_Air_1.34_Air_64_srgb.asset";//出力するtexture3Dのファイル名


        Texture3D texture;
        readfile(input_csvfilename);
        //Debug.Log(Refl1(30,1,1.5,1.6,200,20));
        texture=create_3dtex();
        AssetDatabase.CreateAsset(texture, "Assets/LUTs/"+output_3dtexfilename);//変える
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }
    public double[,,,] strucTable = new double[size,size,size,3];//縦、横、色(*3しているのはRGBあるため)

    void readfile(string input)
    {
        string filePath_1=@"Assets/LUT_Csvs/"+input;//変える
        // StreamReaderクラスをインスタンス化
        StreamReader reader = new StreamReader(filePath_1, Encoding.GetEncoding("UTF-8"));
        
        // 最後まで読み込む
        int count=0;
        int zdep=0;
        while (reader.Peek() >= 0)
        {
            // 読み込んだ文字列をカンマ区切りで配列に格納
            string[] cols = reader.ReadLine().Split(',');
            string vol;
            for(int i=0;i<size*3;i++){
                vol=cols[i];
                if(vol=="nan"){
                    vol="0";
                }
                float a=float.Parse(vol);
                strucTable[i/3,count,zdep,i%3]=a/255;//正規化をする
            }
            
            count++;
            if(count==size){
                count=0;
                zdep++;
            }
        }
        reader.Close();
    }
    
    Texture3D create_3dtex(){
        Texture3D texture;
        Color[] colorArray = new Color[size * size * size];
        texture = new Texture3D (size, size, size, TextureFormat.RGBA32, true);
        float r = 1.0f / (size-1.0f);
        for (int x = 0; x < size; x++) {
            for (int y = 0; y < size; y++) {
                for (int z = 0; z < size; z++) {
                    float B=(float)strucTable[x,y,z,0];//青
                    float G=(float)strucTable[x,y,z,1];//緑
                    float R=(float)strucTable[x,y,z,2];//赤
                    Color c = new Color (R, G, B, 1.0f);
                    colorArray[x + (y * size) + (z * size * size)] = c;
                }
            }
        }
        texture.SetPixels (colorArray);
        texture.Apply ();
        return texture;
    }
    
}
