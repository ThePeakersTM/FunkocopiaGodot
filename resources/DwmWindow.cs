namespace Funkocopia.resources;

using Godot;
using System;
using System.Runtime.InteropServices;

public partial class DwmWindow : Node
{
    private const int DWMWA_BORDER_COLOR = 34;
    private const int DWMWA_CAPTION_COLOR = 35;
    private const int DWMWA_TEXT_COLOR = 36;
    private const int DWMWA_COLOR_DEFAULT = -1;

    public override void _Ready()
    {
        SetCaptionColor(new Color("6963FF"));
        SetBorderColor (new Color("FFE9D5"));
    }

    [DllImport("dwmapi.dll")]
    private static extern int DwmSetWindowAttribute(
        IntPtr hwnd,
        int attribute,
        ref int value,
        int size
    );

    private static IntPtr GetHwnd()
    {
        return new IntPtr(DisplayServer.WindowGetNativeHandle(
            DisplayServer.HandleType.WindowHandle
        ));
    }

    private static int ConvertColor(Color color)
    {
        return 
            (int)(color.R * 255) |
            ((int)(color.G * 255) << 8) |
            ((int)(color.B * 255) << 16);
    }
    
    public static void SetBorderColor(Color color)
    {
        var col = ConvertColor(color);
        
        DwmSetWindowAttribute(
            GetHwnd(),
            DWMWA_BORDER_COLOR,
            ref col,
            sizeof(int)
        );
    }

    public static void SetCaptionColor(Color color)
    {
        var col = ConvertColor(color);
        
        DwmSetWindowAttribute(
            GetHwnd(),
            DWMWA_CAPTION_COLOR,
            ref col,
            sizeof(int)
        );
    }
    
    public static void SetTextColor(Color color)
    {
        var col = ConvertColor(color);
        
        DwmSetWindowAttribute(
            GetHwnd(),
            DWMWA_TEXT_COLOR,
            ref col,
            sizeof(int)
        );
    }
    
    public static void ResetCaptionColor()
    {
        var col = DWMWA_COLOR_DEFAULT;

        DwmSetWindowAttribute(
            GetHwnd(),
            DWMWA_CAPTION_COLOR,
            ref col,
            sizeof(int)
        );
    }
}
