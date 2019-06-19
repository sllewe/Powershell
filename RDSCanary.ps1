###################################################################################
#                                  RDSCanary
#                                  
#  Core Functions
#  1. Logs into a preconfigured RDP file
#  2. Takes a screen shot of the interactive window
#  3. Upload it to blob container
#  4. Take that new file and run it against Azure Computer Vision OCR AI
#  5. Return JSON and parse for Keywords that SHOULD be on the desktop
#  6. Send email if something is not there
################################################################################### 

#creating unique file name 
$file = (get-date -uformat %m-%d-%Y-%H.%M)
#cleaning up old screenshots to avoid confusion
Remove-Item "C:\Temp\Screenshot\*.*" | Where { ! $_.PSIsContainer }
#intiate RDP Connection
mstsc C:\WindowsAzure\RDS.rdp

#allow connection to run
Start-Sleep -Seconds 10

Function Take-ScreenShot { 
  
        [cmdletbinding( 
                SupportsShouldProcess = $True, 
                DefaultParameterSetName = "screen", 
                ConfirmImpact = "low" 
        )] 
Param ( 
       [Parameter( 
            Mandatory = $False, 
            ParameterSetName = "screen", 
            ValueFromPipeline = $True)] 
            [switch]$screen, 
       [Parameter( 
            Mandatory = $False, 
            ParameterSetName = "window", 
            ValueFromPipeline = $False)] 
            [switch]$activewindow, 
       [Parameter( 
            Mandatory = $False, 
            ParameterSetName = "", 
            ValueFromPipeline = $False)] 
            [string]$file,  
       [Parameter( 
            Mandatory = $False, 
            ParameterSetName = "", 
            ValueFromPipeline = $False)] 
            [string] 
            [ValidateSet("bmp","jpeg","png")] 
            $imagetype = "bmp", 
       [Parameter( 
            Mandatory = $False, 
            ParameterSetName = "", 
            ValueFromPipeline = $False)] 
            [switch]$print                        
        
) 

$code = @' 
using System; 
using System.Runtime.InteropServices; 
using System.Drawing; 
using System.Drawing.Imaging; 
namespace ScreenShotDemo 
{ 
 
  public class ScreenCapture 
  { 
    /// <summary> 
    
    public Image CaptureActiveWindow() 
    { 
      return CaptureWindow( User32.GetForegroundWindow() ); 
    } 
   
    public Image CaptureScreen() 
    { 
      return CaptureWindow( User32.GetDesktopWindow() ); 
    }     
   
    private Image CaptureWindow(IntPtr handle) 
    { 
      // target
      IntPtr hdcSrc = User32.GetWindowDC(handle); 
      // size
      User32.RECT windowRect = new User32.RECT(); 
      User32.GetWindowRect(handle,ref windowRect); 
      int width = windowRect.right - windowRect.left; 
      int height = windowRect.bottom - windowRect.top; 
    
      IntPtr hdcDest = GDI32.CreateCompatibleDC(hdcSrc); 
      //bitmap
      IntPtr hBitmap = GDI32.CreateCompatibleBitmap(hdcSrc,width,height); 
      
      IntPtr hOld = GDI32.SelectObject(hdcDest,hBitmap); 
   
      GDI32.BitBlt(hdcDest,0,0,width,height,hdcSrc,0,0,GDI32.SRCCOPY); 

      GDI32.SelectObject(hdcDest,hOld); 
      // clean up 
      GDI32.DeleteDC(hdcDest); 
      User32.ReleaseDC(handle,hdcSrc); 
  
    Image img = Image.FromHbitmap(hBitmap); 
      // more cleanup
      GDI32.DeleteObject(hBitmap); 
      return img; 
    } 
   
    public void CaptureActiveWindowToFile(string filename, ImageFormat format) 
    { 
      Image img = CaptureActiveWindow(); 
      img.Save(filename,format); 
    } 

    public void CaptureScreenToFile(string filename, ImageFormat format) 
    { 
      Image img = CaptureScreen(); 
      img.Save(filename,format); 
    }     
    

    private class GDI32 
    { 
       
      public const int SRCCOPY = 0x00CC0020; // BitBlt dwRop parameter 
      [DllImport("gdi32.dll")] 
      public static extern bool BitBlt(IntPtr hObject,int nXDest,int nYDest, 
        int nWidth,int nHeight,IntPtr hObjectSource, 
        int nXSrc,int nYSrc,int dwRop); 
      [DllImport("gdi32.dll")] 
      public static extern IntPtr CreateCompatibleBitmap(IntPtr hDC,int nWidth, 
        int nHeight); 
      [DllImport("gdi32.dll")] 
      public static extern IntPtr CreateCompatibleDC(IntPtr hDC); 
      [DllImport("gdi32.dll")] 
      public static extern bool DeleteDC(IntPtr hDC); 
      [DllImport("gdi32.dll")] 
      public static extern bool DeleteObject(IntPtr hObject); 
      [DllImport("gdi32.dll")] 
      public static extern IntPtr SelectObject(IntPtr hDC,IntPtr hObject); 
    } 
 

    private class User32 
    { 
      [StructLayout(LayoutKind.Sequential)] 
      public struct RECT 
      { 
        public int left; 
        public int top; 
        public int right; 
        public int bottom; 
      } 
      [DllImport("user32.dll")] 
      public static extern IntPtr GetDesktopWindow(); 
      [DllImport("user32.dll")] 
      public static extern IntPtr GetWindowDC(IntPtr hWnd); 
      [DllImport("user32.dll")] 
      public static extern IntPtr ReleaseDC(IntPtr hWnd,IntPtr hDC); 
      [DllImport("user32.dll")] 
      public static extern IntPtr GetWindowRect(IntPtr hWnd,ref RECT rect); 
      [DllImport("user32.dll")] 
      public static extern IntPtr GetForegroundWindow();       
    } 
  } 
} 
'@ 
#User Add-Type to import the code 
add-type $code -ReferencedAssemblies 'System.Windows.Forms','System.Drawing' 
#Create the object for the Function 
$capture = New-Object ScreenShotDemo.ScreenCapture 
 
#Take screenshot of the entire screen 
If ($Screen) { 
    Write-Verbose "Taking screenshot of entire desktop" 
    #Save to a file 
    If ($file) { 
        If ($file -eq "") { 
            $file = "$pwd\image.bmp" 
            } 
        Write-Verbose "Creating screen file: $file with imagetype of $imagetype" 
        $capture.CaptureScreenToFile($file,$imagetype) 
        } 
    ElseIf ($print) { 
        $img = $Capture.CaptureScreen() 
        $pd = New-Object System.Drawing.Printing.PrintDocument 
        $pd.Add_PrintPage({$_.Graphics.DrawImage(([System.Drawing.Image]$img), 0, 0)}) 
        $pd.Print() 
        }         
    Else { 
        $capture.CaptureScreen() 
        } 
    } 

     
}    

Take-ScreenShot -screen -file "C:\temp\screenshot\screenshot.png" -imagetype png
Rename-Item C:\Temp\screenshot\screenshot.png  -NewName ("C:\temp\screenshot\"+ $file + ".png")

$StorageAccountName = ""
$StorageAccountKey = "key"
$ContainerName = "healthcheck"
$sourceFileRootDirectory = 'C:\Temp\Screenshot' 

function Upload-ToAzure {
    [cmdletbinding()]
    param(
        $StorageAccountName,
        $StorageAccountKey,
        $ContainerName,
        $sourceFileRootDirectory,
        $Force
    )

    $creds = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
    $container = Get-AzureStorageContainer -Name $ContainerName -Context $creds

    $container.CloudBlobContainer.Uri.AbsoluteUri
    if ($container) {
        $filesToUpload = Get-ChildItem $sourceFileRootDirectory -Recurse -File

        foreach ($x in $filesToUpload) {
            $targetPath = ($x.fullname.Substring($sourceFileRootDirectory.Length + 1)).Replace("\", "/")

            Write-Verbose "Uploading $("\" + $x.fullname.Substring($sourceFileRootDirectory.Length + 1)) to $($container.CloudBlobContainer.Uri.AbsoluteUri + "//" + $targetPath)"
            Set-AzureStorageBlobContent -File $x.fullname -Container $container.Name -Blob $targetPath -Context $creds -Force:$Force | Out-Null
        }
    }
}
Upload-ToAzure -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey -ContainerName $ContainerName -sourceFileRootDirectory $sourceFileRootDirectory -Verbose

$reply = $null
$postParams = @{
  'HOST' = "eastus.api.cognitive.microsoft.com";
   'Ocp-Apim-Subscription-Key' = '';
  
}

 $bodyparams = @{
  'url' = "https://.blob.core.windows.net/healthcheck/$file.png"  ;
   
  
}

$body = $bodyparams| ConvertTo-Json

try {
$reply = Invoke-WebRequest 'https://eastus.api.cognitive.microsoft.com/vision/v1.0/ocr?language=unk&detectOrientation =false' -Method Post -Headers $postParams -Body $body -TimeoutSec 10 -UseBasicParsing -ContentType "application/json"
}
catch
{
Write-Host "Error making request"
}

if ($reply.rawContent -match 'Needles')
{

}
else {SendMail}
