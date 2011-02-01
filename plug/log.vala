public class Log : Object{

    public enum Color{
        Black,
        DarkRed,
        DarkGreen,
        DarkYellow,
        DarkBlue,
        DarkMagenta,
        DarkCyan,
        Gray,

        // Light colors
        DarkGray,
        Red,
        Green,
        Yellow,
        Blue,
        Magenta,
        Cyan,
        White,

        // Reset sequence
        Reset
    }

    public static void log_handler (string? domain, LogLevelFlags lvl, string message) {

        if(!should_log(lvl))
            return;
        
        var output = preprocess(message);
        
        prelude(domain, lvl);
        
        stdout.printf(output);

        stdout.printf("\n");
    }
    
    private static string preprocess(string message) {
        string[] output;
        string[] strings = message.split(":");
        if(strings[0].length > 5)
        {
            if(strings[0].has_suffix(".vala"))
            {
                output = strings[2:strings.length];
                if(output[0].has_prefix(" "))
                    output[0] = output[0].strip();
            } else {
                output = strings;
            }
        } else {
            output = strings;
        }
        return string.joinv(":",output);
    }

    private static string get_color_code(Color color, bool foreground){
        var light = false;
        var color_id = 0;
        var reset = false;

        switch (color) {
            // Dark colors
            case Color.Black:        color_id = 0;                  break;
            case Color.DarkRed:      color_id = 1;                  break;
            case Color.DarkGreen:    color_id = 2;                  break;
            case Color.DarkYellow:   color_id = 3;                  break;
            case Color.DarkBlue:     color_id = 4;                  break;
            case Color.DarkMagenta:  color_id = 5;                  break;
            case Color.DarkCyan:     color_id = 6;                  break;
            case Color.Gray:         color_id = 7;                  break;

            // Light colors
            case Color.DarkGray:    color_id = 0; light = true;     break;
            case Color.Red:         color_id = 1; light = true;     break;
            case Color.Green:       color_id = 2; light = true;     break;
            case Color.Yellow:      color_id = 3; light = true;     break;
            case Color.Blue:        color_id = 4; light = true;     break;
            case Color.Magenta:     color_id = 5; light = true;     break;
            case Color.Cyan:        color_id = 6; light = true;     break;
            case Color.White:       color_id = 7; light = true;     break;

            // Reset sequence
            case Color.Reset:       reset = true;                   break;
        }

        if(reset)
            return "\x001b[0m";

        int code = color_id + (foreground ? 30 : 40) + (light ? 60 : 0);
        return "\x001b["+code.to_string()+"m";
    }

    private static void color(Color? foreground, Color? background = null){
        if(foreground != null)
            stdout.printf(get_color_code(foreground, true));

        if(background != null)
            stdout.printf(get_color_code(background, false));
    }

    private static void reset(){
        stdout.printf(get_color_code(Color.Reset, true));
    }

    protected static void prelude(string? domain, LogLevelFlags level){
        stdout.printf ("[%15.15s]", domain);
        
        string name = "";
        
        switch (level) {
            case LogLevelFlags.FLAG_RECURSION:
                color(Color.Red, Color.White);
                name = "Recursion";
                break;
            case LogLevelFlags.FLAG_FATAL:
                color(Color.Red, Color.White);
                name = "Fatal";
                break;
            case LogLevelFlags.LEVEL_CRITICAL:
                color(Color.Red, Color.White);
                name = "Critical";
                break;
            case LogLevelFlags.LEVEL_ERROR:
                color(Color.Yellow);
                name = "Error";
                break;
            case LogLevelFlags.LEVEL_WARNING:
                color(Color.Yellow);
                name = "Warning";
                break;
            case LogLevelFlags.LEVEL_MESSAGE:
                color(Color.DarkMagenta);
                name = "Message";
                break;
            case LogLevelFlags.LEVEL_INFO:
                color(Color.Blue);
                name = "Info";
                break;
            case LogLevelFlags.LEVEL_DEBUG:
                color(Color.Green);
                name = "Debug";
                break;
            case LogLevelFlags.LEVEL_MASK:
                color(Color.Green);
                name = "Mask";
                break;
            default:
                color(Color.Black, Color.DarkYellow);
                name = "undefined";
                break;
        }

        stdout.printf ("[%9s]", name);
        reset();

        stdout.printf(" ");
    }

    private static bool should_log(LogLevelFlags request_level){
//        switch (request_level) {
//            case Level.FATAL:
//                return true;
//            case Level.ERROR:
//                return true;
//            case Level.WARN:
//                return true;
//            case Level.NOTIFY:
//                return true;
//            case Level.INFO:
//                return true;
//            case Level.DEBUG:
//                return true;
//            case Level.UNDEFINED:
//                return true;
//        }

//        return false;

        return true;//request_level <= level;
    }
}

