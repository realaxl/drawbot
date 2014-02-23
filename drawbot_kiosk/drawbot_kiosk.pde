/*
  Drawbot@MfK project 2011
  https://hackerspace-ffm.de/wiki/index.php?title=Drawbot@MfK

  - collect coordinates in plot ArrayList
  - scr: normalize for screen (center, scale)
  - bot: normalize for bot (center, scale, deskew)
*/

import processing.serial.*;
Serial myPort;      // The serial port
int ser_open = 0;
int ser_port_ID = 0;  // 0, 1, 2 ... this depends on the local COM port settings

int ser_byte = -1;    // Incoming serial data
String ser_in, ser_out;

//
// general plot coordinates - object model
// measured as pure float's, will be normalized later
//
class plot_c {
  char m;
  float X, Y;

  // constructor
  plot_c(char im, float iX, float iY) {
    m = im;
    X = iX;
    Y = iY;
  }
}

float Xmin, Xmax, Ymin, Ymax;
float Xspan, Yspan;
float X0, Y0;

ArrayList plot, plot_undo;

//
// bot coordinate system
// measured in mm (!), 0/0 is defined as middle.
// 1/10 of mm will be calculated in draw procedures.
//
// Values MUST match with the bot geometry !!!
//
int bot_ID = 0;
// origin of coordinate system, middle, will be overwritten by bot
float bot_Xo = 482.5, bot_Yo = bot_Xo;
// image center
float bot_X0, bot_Y0;
// plot area from - to, X, Y / will be overwritten by read_bot_cfg()
float bot_Xmin = -19, bot_Xmax = -bot_Xmin;
float bot_Ymin = -15, bot_Ymax = +25;

// span, mm to left & right, top & bottom
float bot_Xspan, bot_Yspan;
// scaler coords --> bot
float bot_scale;
// deskew for some bot setups, only
int bot_deskew = 0;



// init and end commands
String bot_init_string = "D 6 8 "; // old - before identify command support
String bot_ff_string = "D 6 8 "; // old - fast forward string
String bot_end_string = "H ";
String bot_ramp_string = "R 4 8";

// bot finite state machine settings
final int BOT_IDLE        = 10;
final int BOT_INIT_0      = 20;
final int BOT_INIT_1      = 21;
final int BOT_INIT_2      = 22;
final int BOT_DRAW        = 50;
final int BOT_PAUSE       = 60;
final int BOT_HOME_END    = 90;
final int BOT_END         = 91;
final int BOT_DEMO        = 100;
final int BOT_TEXT        = 200;

int bot_state = BOT_IDLE;
int bot_i = 0;
int demo_i = 0;

//
// Segmentation
// the bot firmware tends to draw circles for long lines
// seg_... will split lines into segments
//
float seg_T = 100; // threshold: Split drawn lines into segments (25)
int seg_i = 0;
float seg_dX, seg_dY;
char seg_mode = 'l';

float fast_forward_T = 30000;   // threshold: Fast forward longer lines (30) [mm] 
int fast_forward_X = 0, fast_forward_Y = 0;

boolean save_HPGL_screenshot = false;

//
// HERSHEY fonts
//
int hsh_left, hsh_right, hsh_char;
int hsh_X1, hsh_Y1, hsh_X2, hsh_Y2;

int HSH_SPACE = 20;

int hsh_chars = 500;
// String [] hsh = loadStrings("new 4.txt");
String [] hsh = new String [hsh_chars];
int [] hsh_t = new int [256]; // translation table

//
// Drawbot Trace font
//
final int[] trc_dX = { +1, +1,  0, -1, -1, -1,  0, +1};
final int[] trc_dY = {  0, +1, +1, +1,  0, -1, -1, -1};

String[] trc = new String[256];

//
// Screen stuff
//
PFont myFont = createFont(PFont.list()[19], 14);
PImage img_logo, img_osh;

float t1, t2, t3, t4, t5; // temporary vars
float w1, w2, w3, w4, w5; // temporary vars
float x1, y1, x2, y2, x3, y3;

int start_millis;

//
// Test entry
//
String my_string = "TEXT";
String allowed_chars = "01234567890ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜ ";

//
// Setup
//
void setup() {
  int i;

  String welcome = "Willkommen beim Drawbot KIOSK~";
  welcome += "[0-9] Demo-Motive erzeugen^";
  welcome += "[O] Motiv laden (HPGL Format)^";
  welcome += "[X/Y] spiegeln [S] Drehen^";
  welcome += "[I] Info-Seite [A] Optimizer^";
  welcome += "[P] auf Drawbot plotten";

  plot = new ArrayList();
  plot_undo = new ArrayList();

  scr_setup();
  hsh_read_fontfile();
  trc_setup ();

  read_bot_cfg();

  //mass_gen_hpgl();

  //gen_sample_text("The quick brown fox^jumps over the lazy dog");
  gen_sample_text(welcome);

  scr_normalize();
  bot_normalize();
  scr_redraw(0);
}



//
// DRAWBOT general functions
//
int i = 0, j = 255;
int bar;
int bar_size = 400;


float bot_mX = 0, bot_mY = 0, bot_cX = 0, bot_cY = 0, bot_dX, bot_dY;
int bot_ccX, bot_ccY; // correction coordinates


void draw() {
  if (bot_state == BOT_DEMO) {
    demo_i ++;
    if (demo_i < plot.size())
      scr_redraw(demo_i);
    else
      bot_state = BOT_IDLE;
  }
}


void keyPressed() {
  switch(key) {
      case 'p' :
        if (bot_state == BOT_IDLE) {
          bot_state = BOT_INIT_0;
          i = 0;
          bot_mX = 0; bot_mY = 0; // initial memorized coords = 0
          
          stroke (0, 0, 255);
          scr_redraw(0);

          start_millis = millis(); // start time

          if (ser_open == 0) {
            println(Serial.list());
            String portName = Serial.list()[ser_port_ID];
            myPort = new Serial(this, portName, 57600);
            ser_open = 1;
          } else {
            myPort.write("# *** RESTART Drawbot ***" + char(13));
          }
        }
        break;
      case ' ' :
        switch (bot_state) {
          case BOT_DRAW :
            bot_state = BOT_PAUSE;
            break;
          case BOT_PAUSE :
            bot_state = BOT_DRAW;
            myPort.write("# *** END PAUSE  Drawbot ***" + char(13));
            break;
        }
        break;
      case 'Q' :
        if (bot_state == BOT_DRAW);
          bot_state = BOT_END;
        break;
  } // switch

  // new drawings
  if (bot_state == BOT_IDLE) {
    String hpgl_file;
    switch(key) {
      case '1' :
        background (224); plot_remove(1);
        gen_binary_tree(1);
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;
      case '!' :
        background (224); plot_remove(1);
        gen_binary_tree(0);
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;
      case '2' :
        background (224); plot_remove(1);
        gen_TTT(100, 100, 100, "");
        gen_TTT(300, 100, 100, "#");
        gen_TTT(300, 300, 100, "#x1o5x6o7");
        gen_TTT(100, 300, 100, "x2o6x9o8");
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;
      case '3' :
        background (224); plot_remove(1);
        gen_Dodecahedron(); //gen_star();
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;
      case '4' :
        background (224); plot_remove(1);
        gen_spiral();
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;
      case '$' :
        background (224); plot_remove(1);
        gen_RSS("http://www.heise.de/newsticker/heise-top-atom.xml", "Heise RSS feed");
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;
      case '5' :
        background (224); plot_remove(1);
        gen_heart();
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;
      case '6' :
        background (224); plot_remove(1);
        gen_grid();
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;
      case '7' :
        background (224); plot_remove(1);
//        gen_square();
        gen_n_gon(int(random(3, 8)));
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;
      case '8' :
        background (224); plot_remove(1);
        gen_circles_pattern();
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;
      case '(' :
        background (224); plot_remove(1);
        gen_circular_pattern();
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;
      case '9' :
        background (224); plot_remove(1);
        //gen_sample_text("The quick brown fox jumps over the lazy dog");
        gen_sample_text("DRAWBOT");
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;

      case 't' :
        background (224); plot_remove(1);
        gen_text_from_file("../drawbot_txt.txt");
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;
      
      case '0' :
        background (224); plot_remove(1);
        gen_trc_demo();
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;

      case '"' :
        background (224); plot_remove(1);
        bot_circle(-100, -100, 10, 10);
        bot_circle(+100, +100, 10, 10);
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;

      case 'f' :
        background (224); plot_remove(1);
        hpgl_file = "../samples/fuxcon9_pen_only_Umriss.hpgl";
        gen_hpgl(hpgl_file);
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;
      case 'F' :
        background (224); plot_remove(1);
        hpgl_file = "../samples/fuxcon8_pen_only.hpgl";
        gen_hpgl(hpgl_file);
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;

      case 'j' :
        background (224); plot_remove(1);
        hpgl_file = "../../HPGL/Java/Java_Logo.hpgl";
        gen_hpgl(hpgl_file);
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;

      case 'W' :
        write_g_code();
      break;

      // GRID/Sticker Gallery support disabled / 23.12.2011
      case 'g' :
        background (224); plot_remove(1);
        gen_sticker_gallery(0);
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;
      case 'G' :
        background (224); plot_remove(1);
        gen_sticker_gallery(1);
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;

      case 'h' :
        /* background (224);
        bot_Xmin = -2 * grid_Xspan;
        bot_Xmax = +2 * grid_Xspan;
        bot_Ymin = -1 * grid_Yspan;
        bot_Ymax = +3 * grid_Yspan;
        next_Grid();
        scr_normalize(); bot_normalize(); scr_redraw(0); */
      break;

      case 'H' :
        /*background (224);
        scale_to_Grid();
        scr_normalize(); bot_normalize(); scr_redraw(0);'/
      break;

      case '#' :
        /*background (224);
        if (bot_Xo == 450) {
          bot_Xo = 400;
          bot_Xmin = -180;
          bot_Ymin = -100; bot_Ymax = +350;
        } else {
          bot_Xo = 450;
          bot_Xmin = -210;
          bot_Ymin = -150; bot_Ymax = +250;
        }
        bot_Yo = bot_Xo;        // origin of coordinate system, middle X = Y
        bot_Xmax = -bot_Xmin;     // symetrical X area

        scr_normalize(); bot_normalize(); scr_redraw(0);
        scr_info_screen(); */
       break;

      case 'o' :
        background (224); plot_remove(1);
        String demo_files = "armadillo,Black_Horse,Camel,piggie_sihouette,seahorse_silhouette,unicorn,deer_matt_todd_01,turtle-outline,elephant-animal-outline,sportscar-outline,MfK_Logo_001,DIY";
        String[] list = split(demo_files, ',');
        hpgl_file = "../../drawings/samples/" + list[int(random(0, list.length))] + ".hpgl";
        gen_hpgl(hpgl_file);
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;
      case 'O' :
        background (224); plot_remove(1);
        gen_hpgl("");
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;

      case 'l' :
        background (224); plot_remove(1);
        gen_delimiter();
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;

      case 'c' :
        gen_Caleidoscope(3);
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;
      case 'v' :
        gen_Caleidoscope(int(random(3, 8)));
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;

      case 'C' :
        read_bot_cfg();
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;

      case 'x' :
        plot_mirror_X();
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;
      case 'y' :
        plot_mirror_Y();
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;
      case 's' :
        plot_swap_XY();
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;

      case 'a' :
        plot_optimize();
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;

      case 'R' :
        background (224);
        scr_normalize(); bot_normalize();
        demo_i = 0;
        bot_state = BOT_DEMO;
      break;

      case 'A' :
        analyze_accelerations_on_screen();
      break;

      case 'u' :
        if (plot_undo.size() > 0) {
          background (224);
          // plot_remove(0);
          println("UNDO: " + nf(plot_undo.size(), 1));
          plot = plot_undo;
          scr_normalize(); bot_normalize(); scr_redraw(0);
        }
      break;
      case 'r' :
        background (224);
        scr_normalize(); bot_normalize(); scr_redraw(0);
      break;
      case 'i' :
        scr_info_screen();
      break;
    } // switch
  }

  // text entry mode
  if (bot_state == BOT_TEXT) {
    String skey = "" + key;
    skey = skey.toUpperCase();
    String[] m1 = match(allowed_chars, skey);
    if (m1 != null) {
      my_string = my_string + skey;
    } else {
      switch(key) {
        case BACKSPACE :
          if (my_string.length() > 0)
            my_string = my_string.substring(0, my_string.length() - 1);
        break;
        case ENTER :
          if (my_string.length() > 0)
            bot_state = BOT_IDLE;
        break;
      } // switch
    }
    if (bot_state == BOT_TEXT)
      background (224, 128, 128);
    else
      background (224);
    plot_remove(1);
    gen_sample_text(my_string);
    if (my_string.length() > 0) {
      scr_normalize(); bot_normalize(); scr_redraw(0);
    }
  }
}


//
// execute the next move or draw command
//
// draw commands are split into segments, if needed
//
void bot_next_step() {
  plot_c t_plot;
  float L;
  float elapsed, eta;

  bar = (bar_size * i) / plot.size();
  elapsed = (millis() - start_millis) / 1000;
  if (i > 1)
    eta = elapsed / i * (plot.size() - i);
  else
    eta = 1;
  fill(255, 128, 128);
  rect(width - 5 - bar_size, height - 22, bar, 18);
  fill(255);
  rect(width - 5 - bar_size + bar, height - 22, bar_size - bar, 18);
  fill(0);
  text("Coord: " + nf(i, 1, 0) + " / Time: " + nf(int(elapsed), 1) + " sec. / ETA: " + nf(int(eta), 1),  width - bar_size, height - 6);

  stroke(j, 0, 255 - j);


  if (seg_i > 0) {
    seg_i --;
    if (seg_mode == 'l') {
      bot_ccX = (int) (10 * (bot_X0 + bot_mX - (seg_dX * seg_i))); // ??? have to move this
      bot_ccY = (int) (10 * (bot_Y0 - bot_mY + (seg_dY * seg_i)));
      ser_out = "L " + nfp((int) bot_ccX, 5) + ' ' + nfp((int) bot_ccY, 5);
      println ("bot-test ABSOLUTE: Segment " + nfp(seg_i, 3) + " " + nfp(bot_ccX, 5) + "/" + nfp(bot_ccY, 5));
    }
    if (seg_mode == 'm') {
      if (seg_i == 2) {
        ser_out = "M " + nfp((int) fast_forward_X, 5) + ' ' + nfp((int) fast_forward_Y, 5);
        println ("bot-test FAST-FORWARD: Intermediate move to " + nfp(seg_i, 3) + " " + nfp(fast_forward_X, 5) + "/" + nfp(fast_forward_Y, 5));
      }
      if (seg_i == 1) {
        ser_out = bot_init_string;
        println ("bot-test FAST-FORWARD: Final move to " + nfp(seg_i, 3) + " " + nfp(bot_ccX, 5) + "/" + nfp(bot_ccY, 5));
      }
      if (seg_i == 0) {
        bot_ccX = (int) (10 * (bot_X0 + bot_cX));
        bot_ccY = (int) (10 * (bot_Y0 - bot_cY));
      
        ser_out = "M " + nfp((int) bot_ccX, 5) + ' ' + nfp((int) bot_ccY, 5);
        println ("bot-test FAST-FORWARD: Final move to " + nfp(seg_i, 3) + " " + nfp(bot_ccX, 5) + "/" + nfp(bot_ccY, 5));
      }
    }
  } else {
    // no more segments, new coords:
    t_plot = (plot_c) plot.get(i);
    cX = scr_X0 + scr_scale * (t_plot.X - X0);
    cY = scr_Y0 - scr_scale * (t_plot.Y - Y0);

    bot_cX = bot_scale * (t_plot.X - X0);
    bot_cY = bot_scale * (t_plot.Y - Y0);

    // de-skew?
    if (bot_deskew == 1)
      bot_cX = bot_cX * (1. + ((24. / 110.) * (bot_Y0 - bot_cY - 250.) / 500.));

    // bot coordinates, 1/10ths of mm
    bot_ccX = (int) (10 * (bot_X0 + bot_cX));
    bot_ccY = (int) (10 * (bot_Y0 - bot_cY));
    println ("bot-test ABSOLUTE: " + t_plot.m + " " + nfp(bot_cX, 5,5) + "/" + nfp(bot_cY, 5,5));
    println ("bot-test ABSOLUTE: " + t_plot.m + " " + nfp(bot_ccX, 5) + "/" + nfp(bot_ccY, 5));


    if (t_plot.m == 'l')
      line(mX, mY, cX, cY);

    if (t_plot.m == 'm') {
      L = sqrt(sq(bot_cX - bot_mX) + sq(bot_cY - bot_mY)); // line length
      if (L > fast_forward_T) {                            // check fast forward threshold length
        float L2 = L - fast_forward_T;
        float dX = (bot_cX - bot_mX) * (L2 / L); // calculate intermediate positions
        float dY = (bot_cY - bot_mY) * (L2 / L); // for fast forward movement
        
        // shortened coodinates        
        fast_forward_X = (int) (10 * (bot_X0 + bot_mX + dX));
        fast_forward_Y = (int) (10 * (bot_Y0 - bot_mY - dY));

        seg_mode = 'm';
        seg_i = 3;
        println ("bot-test FAST-FORWARD");
        ser_out = bot_ff_string; // "D 6 20";
      } else {
        ser_out = "M " + nfp((int) bot_ccX, 5) + ' ' + nfp((int) bot_ccY, 5);
      }
    }

    if (t_plot.m == 'l') {
      L = sqrt(sq(bot_cX - bot_mX) + sq(bot_cY - bot_mY)); // line length, check for segmentation
      println ("bot-test ABSOLUTE: L length for segmentation: " + nfp(L, 5, 5));
      if (L > seg_T) {
        seg_mode = 'l';
        seg_i = 1 + (int) (L / seg_T);
        seg_dX = (bot_cX - bot_mX) / seg_i;
        seg_dY = (bot_cY - bot_mY) / seg_i;
        println ("bot-test ABSOLUTE: segmenting in " + nfp(seg_i, 5) + " segments, " + nfp(seg_dX, 5, 5) + "/" + nfp(seg_dY, 5, 5));
        bot_ccX = (int) (10 * (bot_X0 + bot_mX + seg_dX)); // ??? have to move this
        bot_ccY = (int) (10 * (bot_Y0 - bot_mY - seg_dY));
        ser_out = "L " + nfp((int) bot_ccX, 5) + ' ' + nfp((int) bot_ccY, 5);
        seg_i --;
      } else
        ser_out = "L " + nfp((int) bot_ccX, 5) + ' ' + nfp((int) bot_ccY, 5);
    }

    mX = cX;
    mY = cY;
    bot_mX = bot_cX;
    bot_mY = bot_cY;
  }

  if (seg_i == 0)
    if (i < plot.size())
      i ++;
}


//
// catch serial events
//
void serialEvent(Serial myPort) {
  ser_byte = myPort.read();
  if (ser_byte == 13) {
    println("serial IN : " + ser_in);

    if (ser_in.equals("OK")) {
      switch (bot_state) {
        case BOT_INIT_0 :
          ser_out = "i";
          myPort.write(ser_out + char(13));
          bot_state = BOT_INIT_1;
        break;
        case BOT_INIT_1 :
          ser_out = bot_init_string;
          myPort.write(ser_out + char(13));
          bot_state = BOT_INIT_2;
        break;
        case BOT_INIT_2 :
          ser_out = bot_ramp_string;
          myPort.write(ser_out + char(13));
          bot_state = BOT_DRAW;
        break;
        case BOT_DRAW :
          if (i < plot.size()) {
            bot_next_step();
            println("OUT: " + ser_out);
            myPort.write(ser_out + char(13));
          } else {
            ser_out = "H";
            bot_state = BOT_END;
            println("OUT: " + ser_out);
            myPort.write(ser_out + char(13));
          }
        break;
        case BOT_END :
          bot_state = BOT_IDLE;
          // myPort.stop();
        break;
      }
    }
    if (ser_in.length() >= 3)
      if (ser_in.substring(0, 3).equals("#ID")) {
        print ("IDENTIFY: ");
        println(ser_in.substring(5, ser_in.length()));
        int[] nums = int(split(ser_in.substring(5, ser_in.length()), ' '));
        bot_ID = nums[0];

        // bot_ID = 0; // REMOVE THIS

        bot_Xo = int(nums[2] / 10);
        bot_Yo = int(nums[3] / 10);
        read_bot_cfg();
        bot_normalize(); scr_redraw(0);
      }

    ser_in = "";
  } else {
    if (ser_byte >= 32)
      ser_in = ser_in + char(ser_byte);
  }
}

//
// delete the plot ArrayList
//
void plot_remove(int undo) {
  if (undo > 0)
    plot_undo = plot;

  for(int i = plot.size() - 1; i >= 0; i --)
    plot.remove(i);
}


//
// mirror X the plot ArrayList
//
void plot_mirror_X() {
  plot_c t_plot;

  for(int i = plot.size() - 1; i >= 0; i --) {
    t_plot = (plot_c) plot.get(i);
    t_plot.X = -t_plot.X;
  }
}

//
// mirror Y the plot ArrayList
//
void plot_mirror_Y() {
  plot_c t_plot;

  for(int i = plot.size() - 1; i >= 0; i --) {
    t_plot = (plot_c) plot.get(i);
    t_plot.Y = -t_plot.Y;
  }
}


//
// rotate / swap X/Y the plot ArrayList
//
void plot_swap_XY() {
  float f;
  plot_c t_plot;

  for(int i = plot.size() - 1; i >= 0; i --) {
    t_plot = (plot_c) plot.get(i);
    f        = t_plot.Y;
    t_plot.Y = t_plot.X;
    t_plot.X = -f;
  }
}


//
// optimize the plot ArrayList
//
void plot_optimize() {
  int i, ii;
  int segments = 0;
  float f;
  plot_c t_plot;
  String s;
  char a;

  int size_limit = 0;

  ArrayList opt=new ArrayList();

  float opt_Xmin = 0, opt_Xmax = 0, opt_Ymin = 0, opt_Ymax = 0;

  ii = 0;
  for (i = 0; i < plot.size(); i ++) {
    t_plot = (plot_c) plot.get(i);
    if ((t_plot.m == 'm') || (i == plot.size()-1)) {
      if (i > ii) {
        s = "";
        f = Ymax - ((opt_Ymax + opt_Ymin) / 2);
        s = s + nf(floor(f / Yspan * 99), 2, 0) + ".";

        f = (opt_Ymax - opt_Ymin);
        s = s + nf(floor(f / Yspan * 99), 2, 0) + ".";

        f = ((opt_Xmax + opt_Xmin) / 2) - Xmin;
        s = s + nf(floor(f / Xspan * 99), 2, 0) + ".";

        f = (opt_Xmax - opt_Xmin);
        s = s + nf(floor(f / Xspan * 99), 2, 0) + ".";

        s = s + nf(ii, 1) + ".";

        f = sqrt(sq(opt_Xmax - opt_Xmin) + sq(opt_Ymax - opt_Ymin));
        if (f >= size_limit)
          opt.add(new String(s));
        println(s);
      }
      ii = i;
      segments ++;
      opt_Xmin = t_plot.X;
      opt_Xmax = t_plot.X;
      opt_Ymin = t_plot.Y;
      opt_Ymax = t_plot.Y;
//    println("Segment m start: " + nf(ii, 1));
    } else {
      opt_Xmin = min(opt_Xmin, t_plot.X);
      opt_Xmax = max(opt_Xmax, t_plot.X);
      opt_Ymin = min(opt_Ymin, t_plot.Y);
      opt_Ymax = max(opt_Ymax, t_plot.Y);
    }
  }
  println("Segments found: " + nf(segments, 1));
  String opt2[] = new String[opt.size()];      // Argh, need another array, cannot sort() ArrayList
  for(i = 0; i < opt.size(); i ++)
    opt2[i] = (String) opt.get(i);

  opt2 = sort(opt2);
  println(opt2);

  ArrayList plot2;
  plot2 = new ArrayList();

  int[] p = new int[5];
  for (i = 0; i < opt2.length; i ++) {
    p = int(split(opt2[i], "."));
    ii = p[4];
    print("Segment " + opt2[i] + " - positions: " + nf(ii, 1) + " ... ");
    t_plot = (plot_c) plot.get(ii); // the move element
    plot2.add((plot_c) t_plot);
    ii ++; a = 'l';
    while ((ii < plot.size()) && (a == 'l')) {
      t_plot = (plot_c) plot.get(ii);
      a = t_plot.m;
      if (a == 'l')
        plot2.add((plot_c) t_plot); // the line element(s)
      ii ++;
    }
    println(nf(ii, 1));
  }
  println("Compare size: plot = " + nf(plot.size(), 1) + " / plot2 = " + nf(plot2.size(), 1));
  if (plot.size() != plot2.size()) {
      println("Error in optimizer, size difference: plot [source] = " + nf(plot.size(), 1) + " / plot2 [destination] = " + nf(plot2.size(), 1));
  } // else {
  plot_remove(1);
  plot = plot2;
}




//
// get minimum and maximum coordinates in current drawing
//
void get_min_max() {
  int i;
  plot_c t_plot = (plot_c) plot.get(0);

  Xmin = t_plot.X; // initialize on element 0
  Xmax = t_plot.X;
  Ymin = t_plot.Y;
  Ymax = t_plot.Y;

  for (i = 1; i < plot.size(); i ++) {
    t_plot = (plot_c) plot.get(i);
    Xmin = min(Xmin, t_plot.X);
    Xmax = max(Xmax, t_plot.X);
    Ymin = min(Ymin, t_plot.Y);
    Ymax = max(Ymax, t_plot.Y);
  }

  Xspan = Xmax - Xmin;        // span of the plot coordinate system
  Yspan = Ymax - Ymin;

  X0 = Xmin + (Xspan / 2);    // origin of the plot coordinate system = middle
  Y0 = Ymin + (Yspan / 2);
}



//
// normalize sketch to the current bot
//
void bot_normalize() {
  // get plot min and max coordinates
  int i;
  float t1, t2; // temporary vars

  get_min_max();

  bot_Xspan = bot_Xmax - bot_Xmin;
  bot_Yspan = bot_Ymax - bot_Ymin;

  t1 = (Xspan == 0) ? 1 : bot_Xspan / Xspan;
  t2 = (Yspan == 0) ? 1 : bot_Yspan / Yspan;

  bot_scale = max(t1, t2);

  if (((bot_scale * Yspan) > bot_Yspan) || ((bot_scale * Xspan) > bot_Xspan))
    bot_scale = min(t1, t2);

  bot_X0 = bot_Xo + bot_Xmin + (bot_Xmax - bot_Xmin) / 2;
  bot_Y0 = bot_Yo + bot_Ymin + (bot_Ymax - bot_Ymin) / 2;
}


//
// read configuration parameters from XML file
//
void read_bot_cfg() {
  XMLElement bot_cfg;
  bot_cfg = new XMLElement(this, "../common/drawbot_config.xml");
  //println(bot_cfg);

  bot_ID = min(7, max(bot_ID, 0));

  XMLElement bot_cfg_detail = bot_cfg.getChild("bot_" + nf(bot_ID, 1) + "/default");
  int numSites = bot_cfg.getChildCount();

  for (int i = 0; i < bot_cfg_detail.getChildCount(); i++) {
    XMLElement kid = bot_cfg_detail.getChild(i);
    //println(kid);
    String comment = kid.getContent();
    String id = kid.getStringAttribute("id");
    println("#XML: " + id + " / " + comment);

    if (id.length() > 0) {
      if (id.equals("canvas")) {
        bot_Xmin = kid.getFloatAttribute("Xmin");
        bot_Xmax = kid.getFloatAttribute("Xmax");
        bot_Ymin = kid.getFloatAttribute("Ymin");
        bot_Ymax = kid.getFloatAttribute("Ymax");
        println("Xmin = " + nf(Xmin,1,1));
      }
      if (id.equals("speed")) {
        int s1 = kid.getIntAttribute("move_delay");
        int s2 = kid.getIntAttribute("line_delay");
        int s3 = kid.getIntAttribute("move_ff_delay");
        if (s3 >= s2)
          s3 = s2;
        bot_init_string = "D " + nf(s1, 1) + " " + nf(s2, 1) + " ";
        bot_ff_string = "D " + nf(s3, 1) + " " + nf(s2, 1) + " ";
        println("bot_init_string: " + bot_init_string);
      }
      if (id.equals("ramps")) {
        int s1 = kid.getIntAttribute("ramp_acc");
        int s2 = kid.getIntAttribute("ramp_dec");
        s1 = max(1, min(255, s1));
        s2 = max(1, min(255, s2));
        bot_ramp_string = "R " + nf(s1, 1) + " " + nf(s2, 1) + " ";
        println("bot_ramp_string: " + bot_ramp_string);
      }
      if (id.equals("geometry")) {
        bot_deskew = kid.getIntAttribute("deskew");
        if (bot_deskew != 0)
          bot_deskew = 1;
      }
    }
  }
}


//
// write a g-code file (experimental)
//
void write_g_code() {
  float move_height = 2;
  float mill_height = -0.35;
  float g_scale = (23. / 90.) * 135. / 154.;
  float g_feed = 80;

  int drill = 0;

  ArrayList s;  // String collection
  s = new ArrayList();  // Create an empty ArrayList

  s.add(new String("%"));
  s.add(new String("( XYZ_Blinkenlights )"));
  s.add(new String("( LED circles for CNC routers )"));
  s.add(new String("( 2011-12 AXL / Hackerspace FFM )"));
  s.add(new String("G21 (All units in mm)"));
  s.add(new String("G00 Z" + fpp(move_height)));

  plot_c t_plot;

  float gx, gy;
  for(int i = 0; i < plot.size(); i ++) {
    t_plot = (plot_c) plot.get(i);
    gx = t_plot.X * g_scale;
    gy = t_plot.Y * g_scale;

    switch (t_plot.m) {
      case 'm' :
        if (drill == 1)
          s.add(new String("G00 Z" + fpp(move_height)));
        s.add(new String("G00 X" + fpp(gx) + " Y" + fpp(gy)));
        drill = 0;
      break;
      case 'l' :
        if (drill == 0)
          s.add(new String("G01 Z" + fpp(mill_height)  + " F" + fpp(g_feed)));
        s.add(new String("G01 X" + fpp(gx) + " Y" + fpp(gy) + " Z" + fpp(mill_height) + " F" + fpp(g_feed)));
        drill = 1;
      break;
    }
  }


  s.add(new String("G00 Z" + fpp(move_height)));
  s.add(new String("G00 X0 Y0"));
  s.add(new String("%"));

  //
  // write to file
  //
  PrintWriter output;
  output = createWriter("../drawbot_g-code.ngc");
  for (int i = 0; i < s.size(); i ++)
    output.println(s.get(i));

  output.flush(); // Writes the remaining data to the file
  output.close(); // Finishes the file

}


//
// convert a float to #.###
//
String fpp(float f) {
  String s = nf(f, 1, 3);
  s = s.replace(',', '.');
  return(s);
}

//
// add a coordinate to the plot_c list
//
void p(char m, float x, float y) {
  plot.add(new plot_c(m, x, y));
}
