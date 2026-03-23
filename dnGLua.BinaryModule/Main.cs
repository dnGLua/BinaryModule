public static unsafe class Main
{
  [UnmanagedCallersOnly(EntryPoint = "gmod13_open", CallConvs = [typeof(CallConvCdecl)])]
  public static int GMOD_MODULE_OPEN(void* L)
  {
#if CLIENT
#if NATIVE_AOT
    User32.MessageBoxA(0, "C# says hello client from .NET NativeAOT\0"u8, "GMod Binary Module\0"u8, 0u);
#else
    User32.MessageBoxA(0, "C# says hello client from managed .NET\0"u8, "GMod Binary Module\0"u8, 0u);
#endif
#else
#if NATIVE_AOT
    User32.MessageBoxA(0, "C# says hello server from .NET NativeAOT\0"u8, "GMod Binary Module\0"u8, 0u);
#else
    User32.MessageBoxA(0, "C# says hello server from managed .NET\0"u8, "GMod Binary Module\0"u8, 0u);
#endif
#endif
    //var result = NativeLib.GreetingsNativeFunc("Cheatoid\0"u8, 1337);
    //MessageBoxA(0, "result: " + result, "C# GMod Binary Module", 0u);
    return 0;
  }

  [UnmanagedCallersOnly(EntryPoint = "gmod13_close", CallConvs = [typeof(CallConvCdecl)])]
  public static int GMOD_MODULE_CLOSE(void* L)
  {
    //User32.MessageBoxA(0, "Closing down...\0"u8, "C# GMod Binary Module"u8, 0u);
    return 0;
  }
}

internal unsafe interface INativeLib
{
  double GreetingsNativeFunc(sbyte* name, double num);

  [MethodImpl(MethodImplOptions.AggressiveInlining)]
  double GreetingsNativeFunc(ReadOnlySpan<byte> name, double num)
  {
#if EXPERIMENTAL_AVOID_PINNING
    return GreetingsNativeFunc((sbyte*)Unsafe.AsPointer(ref MemoryMarshal.GetReference(name)), num);
#else
    fixed (void* name_ = name)
      return GreetingsNativeFunc((sbyte*)name_, num);
#endif
  }
}

[SupportedOSPlatform("windows")]
public unsafe interface IUser32
{
  int MessageBoxA(HWND hWnd, sbyte* lpText, sbyte* lpCaption, UINT uType);

  [MethodImpl(MethodImplOptions.AggressiveInlining)]
  int MessageBoxA(HWND hWnd, ReadOnlySpan<byte> lpText, ReadOnlySpan<byte> lpCaption, UINT uType)
  {
#if EXPERIMENTAL_AVOID_PINNING
    return MessageBoxA(hWnd, (sbyte*)Unsafe.AsPointer(ref MemoryMarshal.GetReference(lpText)), (sbyte*)Unsafe.AsPointer(ref MemoryMarshal.GetReference(lpCaption)), uType);
#else
    fixed (void* lpText_ = lpText, lpCaption_ = lpCaption)
      return MessageBoxA(hWnd, (sbyte*)lpText_, (sbyte*)lpCaption_, uType);
#endif
  }
}

internal static unsafe partial class NativeMethods
{
  private const string mynativelib = "mynativelib", kernel32 = "kernel32", user32 = "user32";

  [DllImport(mynativelib, CallingConvention = CallingConvention.Cdecl)]
  internal static extern double GreetingsNativeFunc(sbyte* name, double num);

  [LibraryImport(user32, EntryPoint = "MessageBoxA", StringMarshalling = StringMarshalling.Utf8)]
  [UnmanagedCallConv(CallConvs = [typeof(CallConvStdcall)])]
  internal static partial int MessageBoxA(HWND hWnd, string lpText, string lpCaption, UINT uType);

  [NativeImport(mynativelib, CallingConvention = CallingConvention.Cdecl, Lazy = true)]
  internal static partial INativeLib NativeLib { get; }

  [NativeImport(user32, CallingConvention = CallingConvention.StdCall, Lazy = true)]
  internal static partial IUser32 User32 { get; }
}
