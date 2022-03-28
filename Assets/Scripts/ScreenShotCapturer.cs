using UnityEngine;

/// <summary>
/// スクリーンショットをキャプチャするサンプル
/// </summary>
public class ScreenShotCapturer : MonoBehaviour
{
    private void Update()
    {
        // スペースキーが押されたら
        if (Input.GetKeyDown(KeyCode.Space))
        {
            // スクリーンショットを保存
            CaptureScreenShot("J:\\Datafolder\\Unity\\shader\\shader素材画像\\bubble_asahina.png");
        }
    }

    // 画面全体のスクリーンショットを保存する
    private void CaptureScreenShot(string filePath)
    {
        ScreenCapture.CaptureScreenshot(filePath);
    }
}