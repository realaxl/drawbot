/*
  Drawbot
  https://hackerspace-ffm.de/wiki/index.php?title=Drawbot@MfK

  Image generators
*/


// ==========================================================================
// Binary tree #002 - contour
//   95 sec @ 35 ms delay
//   71 sec @ 25 ms delay
// ==========================================================================
void gen_binary_tree(float r) {
  t1 = 30;   // start length
  t2 = random(0.65,0.79);  // < 1 !!! reduction per iteration
  t3 = random(0.0600, 0.15);  // < 1; ratio length / thickness
  t4 = 6;    // minimal branch length
  t5 = r;

  w1 = 90;   // start angle
  w2 = random(15, 45);   // delta angle

  p('m', -t1 * t3, 0);
  branch (0, 0, t1, w1);
  p('l', t1 * t3, 0);
  p('l', -t1 * t3, 0);
}

void branch(float x1, float y1, float l, float w) {
  float x2, y2; // skeleton
  float x3, y3; // hull
  float l2, t; // next iteration

  t = l * t3; // thickness
  l2 = l * t2;

  x2 = x1 + l * cos(radians(w));
  y2 = y1 + l * sin(radians(w));

  x3 = x2 + t * cos(radians(w + 90));
  y3 = y2 + t * sin(radians(w + 90));
  plot.add(new plot_c('l', x3, y3));

  if (l2 > t4)
    branch (x2, y2, l2 * (1 + t5 * random(-.2, +.1)), w + w2 * (1 + t5 * random(-.3, +.3)));

  x3 = x2 + 1.3 * t * cos(radians(w));
  y3 = y2 + 1.3 * t * sin(radians(w));
  p('l', x3, y3);

  if (l2 > t4)
    branch (x2, y2, l2 * (1 + t5 * random(-.2, +.1)), w - w2 * (1 + t5 * random(-.3, +.3)));

  x3 = x2 + t * cos(radians(w - 90));
  y3 = y2 + t * sin(radians(w - 90));
  p('l', x3, y3);
}


void gen_circular_pattern() {
  float r = 20;
  float w;
  float mx = 0, my = 0;

  String pattern = "90,60,120,120,120,120,120,210,120,120,120,120,120,210,120,120,120,120,120,210,120,120,120,120,120,150";

  float[] list = float(split(pattern, ','));

  w = list[0];
  int step = 1;

  float x = mx + r * cos(radians(w));
  float y = my + r * sin(radians(w));
  p('m', x, y);

  for (int i = 1; i < list.length; i ++) {
    for (int j = 0; j < list[i]; j ++) {
      w += step;
      x = mx + r * cos(radians(w));
      y = my + r * sin(radians(w));
      p('l', x, y);
    }
    // new center
    mx += 2 * r * cos(radians(w));
    my += 2 * r * sin(radians(w));
    w = w + 180;
    step = -step;
  }
}


// ==========================================================================
// STAR
// ==========================================================================
void gen_star () {
  t2 = 12 * int(random(2,4));
  t3 = 100;
  t4 = random(20, 80);
  char cc;
  for (t1 = 0.; t1 <= 360; t1 += t2) {

    float w;
    cc = (t1 == 0) ? 'm' : 'l';

    w = t1;
    x1 = t3 * cos(radians(w));
    y1 = t3 * sin(radians(w));
    p(cc, x1, y1);

    if (t1 < 360) {
      w = t1 + (t2 / 2);
      x1 = t4 * cos(radians(w));
      y1 = t4 * sin(radians(w));
      p('l', x1, y1);
    }
  }
}

// ==========================================================================
// gen_Dodecahedron
// ==========================================================================
void gen_Dodecahedron () {
  float ru = 100;
  float ri = ru *sqrt(25 + 10 * sqrt(5)) / sqrt(50 + 10 * sqrt(5));
  float iw, w, x, y, x0 = 0, y0 = 0;
  final int lax[] = { 2, 2, 0, 8, 26, 19, 17, 25, 24, 11 };

  gen_pentagon (x0, y0, ru, 90, 0);
  for (iw = 0; iw < 5; iw++) {
    w = 90 - 36 + 72 * iw;
    x = x0 + 2 * ri * cos(radians(w));
    y = y0 + 2 * ri * sin(radians(w));
    gen_pentagon (x, y, ru, w, lax[int(iw)]);
  }

  x0 +=  6 * ri * cos(radians(90 - 36 - 72));
  y0 +=  2 * ri * sin(radians(90 - 36 - 72));

  gen_pentagon (x0, y0, ru, -90, 0);
  for (iw = 0; iw < 5; iw++) {
    w = -90 + 36 + 72 * iw;
    x = x0 + 2 * ri * cos(radians(w));
    y = y0 + 2 * ri * sin(radians(w));
    gen_pentagon (x, y, ru, w, lax[int(iw + 5)]);
  }
}


// ==========================================================================
// single pentagon
// ==========================================================================
void gen_pentagon (float x0, float y0, float ru, float w0, int lax) {
  float ri = ru *sqrt(25 + 10 * sqrt(5)) / sqrt(50 + 10 * sqrt(5));
  float iw, w, x, y;

  char cc;
  for (iw = 0; iw <= 5; iw++) {
    cc = (iw == 0) ? 'm' : 'l';

    w = w0 + 72 * iw;
    x = x0 + ru * cos(radians(w));
    y = y0 + ru * sin(radians(w));
    p(cc, x, y);
  }

  hsh_char_rs('A', x0, y0, 90 - w0, ru / 24);

  /*w = w0;
  x = x0 + ru / 2 * cos(radians(w));
  y = y0 + ru / 2 * sin(radians(w));
  plot.add(new plot_c('m', x, y));

  w += 180;
  x = x0 + ru / 2 * cos(radians(w));
  y = y0 + ru / 2 * sin(radians(w));
  plot.add(new plot_c('l', x, y));
*/

  // Draw the laxes
  for (iw = 0; iw <= 5; iw++) {
    float rl = ru * 1.1;
    if((lax & int(pow(2, iw))) > 0) {
      w = w0 + 72 * iw;
      x = x0 + ru * cos(radians(w));
      y = y0 + ru * sin(radians(w));
      p('m', x, y);

      w += 30;
      x = x0 + rl * cos(radians(w));
      y = y0 + rl * sin(radians(w));
      p('l', x, y);

      w += 12;
      x = x0 + rl * cos(radians(w));
      y = y0 + rl * sin(radians(w));
      p('l', x, y);

      w += 30;
      x = x0 + ru * cos(radians(w));
      y = y0 + ru * sin(radians(w));
      p('l', x, y);

/*      w -= 36;
      x = x0 + (ru + ri) / 2 * cos(radians(w));
      y = y0 + (ru + ri) / 2 * sin(radians(w));
      hsh_char_rs('X', x, y, 90 - w, ru / 125); */
    }
  }
}


// ==========================================================================
// Spirale
// ==========================================================================
void gen_spiral () {
  float w;
  char cc;
  float w1, w2;

  w1 = random(0, 360);
  w2 = random(480, 4000);

  cc = 'm';
  for (w = w1; w <= w2; w += 5) {
    x1 = w / 10 * cos(radians(w));
    y1 = w / 10 * sin(radians(w));
    p(cc, x1, y1);
    cc = 'l';
  }
}


// ==========================================================================
// HERZ / HEART
// anonymous source and obtained from the log files of
// Wolfram|Alpha in early February 2010
// 77 sec. @ 25 ms delay
// ==========================================================================

void gen_heart() {
  float w, r;
  char cc;

  t2 = random(1.33, 2);

  for (t1 = 2; t1 <= 10; t1 = t1 * t2)
    for (i = 0; i <= 360; i += 3) {
      cc = (i == 0) ? 'm' : 'l';

      w = radians(i);
      r = 2 - 2 * sin(w) + sin(w) * (sqrt(abs(cos(w)))) / (sin(w) + 1.4);
      x1 = t1 * r * cos(w);
      y1 = t1 / 3 + t1 * r * sin(w);
      p(cc, x1, y1);
    }
}

// ==========================================================================
// HERSHEY font on sinus
// ==========================================================================
void gen_text_sinus() {
  String s = "Drawbot im MfK";

  int hsh_cursor = 0;
  float kk = 1.;
  char cc;

  float w0 = random(0,360);
  float w1 = random(.5,1.5);
  float w;


  hsh_cursor = 0; cc = 'm';
  for (i = -2; i <= s.length() + 3; i ++) {
    hsh_cursor = i * 20;
    w = w0 + w1 * hsh_cursor;
    p(cc, 20 + hsh_cursor * kk, -20 + 30 * sin(radians(w)));
    cc = 'l';
  }
  hsh_cursor = 0;
  for (i = 0; i < s.length(); i ++) {
    hsh_cursor += 20;
    w = w0 + w1 * hsh_cursor;
    hsh_char_rs((char) s.charAt(i), 20 + hsh_cursor * kk, 30 * sin(radians(w)), -30 * cos(radians(w)), 1);
  }
}


// ==========================================================================
// Grid
// ==========================================================================
void gen_grid() {
  t2 = grid_Xspan * grid_Xmax / 2;

  for (t1 = 0; t1 <= grid_Ymax; t1 ++) {
    t3 = grid_Yspan * t1;
    if((t1 % 2.) == 0.) {
      p('m', -t2, t3);
      p('l', +t2, t3);
    } else {
      p('m', +t2, t3);
      p('l', -t2, t3);
    }
  }

  for (t1 = 0; t1 <= grid_Xmax; t1 ++) {
    t3 = -t2 + grid_Xspan * t1;
    t4 = grid_Yspan * grid_Ymax;
    if((t1 % 2.) == 0.) {
      p('m', t3, 0);
      p('l', t3, t4);
    } else {
      p('m', t3, t4);
      p('l', t3, 0);
    }
  }
}


// ==========================================================================
// Single Square
// ==========================================================================
void gen_square() {
  p('m', 1., 1.);
  p('l', 6., 1.);
  p('l', 6., 6.);
  p('l', 1., 6.);
  p('l', 1., 1.);
}


// ==========================================================================
// Single n-gon
// ==========================================================================
void gen_n_gon(int n) {
  if (n > 2) {
    for (int i = 0; i <= n; i ++) {
      char a = '#';
      float w = (360 / n) * 0.5 + (360. * i) / n;
      float x = 2 * cos(radians(w));
      float y = 2 * sin(radians(w));
      p(a, x, y);
    }

    for (int i = 0; i <= n; i ++) {
      char a = (i == 0) ? 'm' : 'l';
      float w = (360 / n) * 0.5 + (360. * i) / n;
      float x = cos(radians(w));
      float y = sin(radians(w));
      p(a, x, y);
    }
  }
}


// ==========================================================================
// Test pattern, circles
// ==========================================================================
void gen_circles_pattern() {
  float x, y, rx = 8, m = 20;
  float rxx = rx / 5;

  for (y = -2; y <= 2; y++)
    for (x = -3; x <= 3; x++) {
      bot_circle(x * m, y * m, rx, rx);
      p('m', x * m - rxx, y * m);
      p('l', x * m + rxx, y * m);
      p('m', x * m, y * m - rxx);
      p('l', x * m, y * m + rxx);
    }
}


// ==========================================================================
// ut3c - The Ultimate TicTacToe Challenge
// ==========================================================================
//  7 | 8 | 9
// ---+---+---
//  4 | 5 | 6
// ---+---+---
//  1 | 2 | 3

// m0x, m0y ................ center coords
// s0x ..................... size
// s ....................... moves (example: "x1o5x9o8")

void gen_TTT(float m0x, float m0y, float s0x, String s) {
  float s0y = s0x;
  // percentage of field usage
  float s0p = 0.75;

  // grid deltas
  float dx = s0x * s0p /6;
  float dy = s0y * s0p /6;

  // element size O or X
  float rx = s0x * s0p / 12;
  float ry = s0y * s0p / 12;

  // the invisible grid (outer boundaries)
  p('#', m0x-s0x/2, m0y-s0x/2); p('#', m0x+s0x/2, m0y+s0x/2);

  int i = 0;

  if((s.length() > 0) && (s.charAt(0)== '#')) {
    // the TTT Grid
    p('m', m0x-dx*3, m0y-dy*1); p('l', m0x+dx*3, m0y-dy*1);
    p('m', m0x+dx*3, m0y+dy*1); p('l', m0x-dx*3, m0y+dy*1);
    p('m', m0x-dx*1, m0y+dy*3); p('l', m0x-dx*1, m0y-dy*3);
    p('m', m0x+dx*1, m0y-dy*3); p('l', m0x+dx*1, m0y+dy*3);
  
    // the TTT Grid outline
    p('m', m0x+dx*3, m0y+dy*3); 
    p('l', m0x+dx*3, m0y-dy*3);
    p('l', m0x-dx*3, m0y-dy*3);
    p('l', m0x-dx*3, m0y+dy*3);
    p('l', m0x+dx*3, m0y+dy*3);
    
    i ++;
  }

  // the TTT Moves
  while(i < s.length()) {
    char t = s.toLowerCase().charAt(i);
    char p = s.charAt(i+1);

    int pi = max(0, min(9, p - '1'));
    int x = pi % 3;
    int y = int(pi / 3);

    println(i + " / " +t+" "+(pi+1)+" ("+x+"/"+y+")"+s.length());

    float emx = m0x + dx * 2 * (x - 1);
    float emy = m0y + dy * 2 * (y - 1);

    if(t == 'x') {
      p('m', emx - rx, emy - ry); p('l', emx + rx, emy + ry);
      p('m', emx + rx, emy - ry); p('l', emx - rx, emy + ry);
    } else
      bot_circle(emx, emy, rx, ry);

    i += 2;
  }

  // bot_circle(x * m, y * m, rx, rx);
}


// ==========================================================================
// Caleidoscope the current image
// ==========================================================================
void gen_Caleidoscope(int n) {
  float a = 360.0 / n;

  float cal_x = Xspan / 2;
  float cal_y = Yspan / 2 + Xspan / (2 * tan(radians(a / 2)));

  float mx = X0;
  float my = Y0 - cal_y;

  int dots = plot.size();
  plot_c t_plot;

  float rs, rc; //sin, cos of rotation matrix
  if (dots < 100000) {
    for (int i = 1; i < n; i ++) {
      float w = a * i;
      float w2 = -w;

      if (w2 == 0) {
        rs = 0; rc = 1;
      } else {
        rs = sin(radians(w2)); rc = cos(radians(w2));
      }

      float cx  = mx + cal_y * sin(radians(w));
      float cy  = my + cal_y * cos(radians(w));
  //    plot.add(new plot_c('m', mx, my));
  //    plot.add(new plot_c('l', cx, cy));

      for(int j = 0; j < dots; j ++) {
        t_plot = (plot_c) plot.get(j);
        float x = (t_plot.X - X0) * rc - (t_plot.Y - Y0) * rs;
        float y = (t_plot.X - X0) * rs + (t_plot.Y - Y0) * rc;
        p(t_plot.m, x + cx, y + cy);
      }
    }
  }
}



//
// delimiter drawing, will destoy current image !
//
void gen_delimiter() {
  float l;

  l = (Xspan + Yspan) / 2 / 10;

  p('m', Xmin, Ymin);
  p('l', Xmax, Ymin);
  p('l', Xmax, Ymax);
  p('l', Xmin, Ymax);
  p('l', Xmin, Ymin);
}


// ==========================================================================
// HPGL demo 
// - read file hpgl_file
//   or (if empty)
//   file select dialogue
// ==========================================================================
int gen_hpgl(String hpgl_file) {
  BufferedReader reader;
  String s = "", p;
  int i, comma, x, y;

  if (hpgl_file.equals(""))
    hpgl_file = selectInput();  // Opens file select dialog

  println("HPGL file: " + hpgl_file);

  if (hpgl_file == null) {
    gen_sample_text ("*** gen_hpgl() error ***~NO HPGL FILE SPECIFIED!");
    return(0);
  }

  s = hpgl_file.substring(hpgl_file.length() - 5, hpgl_file.length()).toLowerCase();
  println(s + "*");

  if (!s.equals(".hpgl")) {
    gen_sample_text ("*** gen_hpgl() error ***~CAN READ FROM HPGL FILES, ONLY!");
    return(0);
  }


  reader = createReader(hpgl_file);
  s = "";
  i = 0;
  while (i == 0) {
    try {
      p = reader.readLine();
    } catch (IOException e) {
      e.printStackTrace();
      p = null;
      i = 1;
    }
    if (p != null)
    {
      println("p found");
      s = s + p;
      i ++;
    }
  }

  println("Start HPGL decomposition ...");

  String[] hpgl = split(s, ";");

  println("Split returned " + nf(hpgl.length, 1) + " elements.");


  for (i = 0; i < hpgl.length; i ++) {
    p = hpgl[i];
    if (p.length() > 1)
      if (p.charAt(0) == 'P') {
        comma = p.indexOf(",");
        if (comma > 0) {
          x = int(p.substring(2, comma));
          y = -int(p.substring(comma + 1, p.length()));
          if (p.charAt(1) == 'U')
            p('m', x, y);
          if (p.charAt(1) == 'D')
            p('l', x, y);
        }
      }
  }
  
  scr_normalize(); bot_normalize(); scr_redraw(0);
  
  // save PNG screenshot
  if (save_HPGL_screenshot) {
    String png = hpgl_file.substring(0, hpgl_file.length() - 5) + ".png";
    save(png);
    println("Saved PNG file: " + png);
  }
  
  return(1);
}


void mass_gen_hpgl() {
  String[] hpgl_files = {
    "anime_girl_face.hpgl",
    "armadillo.hpgl",
    "AT-AT.hpgl",
    "Black Horse.hpgl",
    "Camel.HPGL",
    "Club_mate_logo.hpgl",
    "Coca-Cola_logo.hpgl",
    "deer_matt_todd_01.hpgl",
    "Dharma-logo.hpgl",
    "dragon-head-silhouette.hpgl",
    "dragon_yves_guillou_01.hpgl",
    "duck.hpgl",
    "eagle+shiloete.HPGL",
    "English_Man_of_War_Cutter_circa_1800.hpgl",
    "flower5.hpgl",
    "Guitar_Rock.hpgl",
    "lizard_01.hpgl",
    "McDonald's_Golden_Arches.hpgl",
    "monkey_band.hpgl",
    "Ornamental_vine_leaves_1879.hpgl",
    "oshw-logo.hpgl",
    "piggie_sihouette.hpgl",
    "rocket-to-the-moon.hpgl",
    "seahorse_silhouette.hpgl",
    "sheep_pecora_architetto_france_01.hpgl",
    "The_man_machine.hpgl",
    "unicorn.hpgl",
    "yoga_person.hpgl",
    "Koffein_-_Caffeine.hpgl",
    "MC_Escher_single_lizard_tile.hpgl",
    "Caduceus.hpgl",
    "Futurama_Planet_Express.hpgl",
    "bottle.hpgl",
    "HexLab_bi-wall.hpgl",
    "Dragonfly Tribal Style.hpgl",
    "Bird Tribal Style.hpgl",
    "ubuntu_black_st_hex.hpgl",
    "Projects_001.hpgl"
  };
  
  for (String s : hpgl_files)
    new_hpgl(s);
}

void new_hpgl(String s) {
  background (224); plot_remove(1);
  gen_hpgl("P:\\prj\\Drawbot\\Beispiele\\HPGL\\" + s);
}

void gen_sample_text(String sd) {
  int kk = 9, k, i;     // scaler
  int max_tX = 300;  // max. line "pixels", regular break
  int lim_tX = max_tX * 12 / 10;  // max. line "pixels", absolute break
  int tLH = 16;      // line height "pixels"

  int tX = 0, tY = 0;
  int sX = 0, sR;
  char a;

  String su;

  println(sd);
  su = sd.toUpperCase();
  k = kk + 0; //= (a == u) ? kk : kk - 1;

  for (i = 0; i < sd.length(); i ++) {
    a = su.charAt(i);

    if (tX >= lim_tX) {
      tX = 0; sX = 0;
      tY -= tLH;
    }

    switch (a) {
      case ' ' :
        if (tX >= max_tX) {
          tX = 0; sX = 0;
          tY -= tLH;
        } else
          if(tX != 0) {
            sR = (2 + trc_char(a, sX, tY * k, k));
            tX += sR;
            sX += sR * k;
          }
      break;
      case '-' :
        sR = (2 + trc_char(a, sX, tY * k, k));
        tX += sR;
        sX += sR * k;
        if (tX >= max_tX) {
          tX = 0; sX = 0;
          tY -= tLH;
        }
      break;
      case '^' :
        tX = 0; sX = 0;
        tY -= tLH;
        k = kk;
      break;
      case '~' :
        tX = 0; sX = 0;
        tY -= (int) (tLH * 3 / 2);
        k = kk;
      break;
      default :
        sR = (2 + trc_char(a, sX, tY * k, k));
        tX += sR;
        sX += sR * k;
      break;
    }
//    trc_string(sd[i].toUpperCase(), 0, -16 * i * kk, kk);
  }
}


// get a text page from a text file
// 17-02-2014 from ../drawbot_text.txt
void gen_text_from_file(String txt_file) {
  String lines[] = loadStrings(txt_file);
  String concat_string = "";
  
  println("gen_text_from_file(): there are " + lines.length + " lines");
  if (lines.length == 0) {
    concat_string = txt_file + "^File is empty!";
  } else {
    for (int i = 0 ; i < lines.length; i++) {
      println(lines[i]);
      if (i > 0)
        concat_string += "^";
      concat_string += lines[i];
    }
  }
  gen_sample_text(concat_string);
}

//
// Drawbot Trace font demo
//
void gen_trc_demo() {
  int i, j, ii;
  int x = 0;

  for (i = 0; i < 7; i ++) {
    x = 0;
    for (j = 0; j < 13; j ++) {
      ii = 32 + i * 13 + j;
      x = x + 2 + trc_char(ii, x * 8, -i * 104, 8);
    }
  }
}


// ==========================================================================
// HERSHEY fonts
// ==========================================================================
void hsh_read_fontfile() {
  BufferedReader reader;
  int i;

  reader = createReader("../common/font_hershey_join.txt");

  String s;
  for (i = 0; i < hsh_chars; i ++)
  {
    s = null;
    while(s == null)  {
      try {
        s = reader.readLine();
      } catch (IOException e) {
        e.printStackTrace();
        s = null;
      }
    }
    hsh[i] = s;
  }

  // mapping table
  // need to fix this ... ???
  hsh_t[32] = 32; hsh_t[33] = 265; hsh_t[34] = 268; hsh_t[35] = 284;
  hsh_t[36] = 270; hsh_t[37] = 68; hsh_t[38] = 285; hsh_t[39] = 267;
  hsh_t[40] = 272; hsh_t[41] = 273; hsh_t[42] = 279; hsh_t[43] = 276;
  hsh_t[44] = 262; hsh_t[45] = 275; hsh_t[46] = 261; hsh_t[47] = 271;
  hsh_t[48] = 251; hsh_t[49] = 252; hsh_t[50] = 253; hsh_t[51] = 254;
  hsh_t[52] = 255; hsh_t[53] = 256; hsh_t[54] = 257; hsh_t[55] = 258;
  hsh_t[56] = 259; hsh_t[57] = 260; hsh_t[58] = 263; hsh_t[59] = 264;
  hsh_t[60] = 68; hsh_t[61] = 277; hsh_t[62] = 68; hsh_t[63] = 266;
  hsh_t[64] = 68; hsh_t[65] = 89; hsh_t[66] = 90; hsh_t[67] = 91;
  hsh_t[68] = 92; hsh_t[69] = 93; hsh_t[70] = 94; hsh_t[71] = 95;
  hsh_t[72] = 96; hsh_t[73] = 97; hsh_t[74] = 98; hsh_t[75] = 99;
  hsh_t[76] = 100; hsh_t[77] = 101; hsh_t[78] = 102; hsh_t[79] = 103;
  hsh_t[80] = 104; hsh_t[81] = 105; hsh_t[82] = 106; hsh_t[83] = 107;
  hsh_t[84] = 108; hsh_t[85] = 109; hsh_t[86] = 110; hsh_t[87] = 111;
  hsh_t[88] = 112; hsh_t[89] = 113; hsh_t[90] = 114; hsh_t[91] = 68;
  hsh_t[92] = 68; hsh_t[93] = 68; hsh_t[94] = 68; hsh_t[95] = 68;
  hsh_t[96] = 68; hsh_t[97] = 166; hsh_t[98] = 167; hsh_t[99] = 168;
  hsh_t[100] = 169; hsh_t[101] = 170; hsh_t[102] = 171; hsh_t[103] = 172;
  hsh_t[104] = 173; hsh_t[105] = 174; hsh_t[106] = 175; hsh_t[107] = 176;
  hsh_t[108] = 177; hsh_t[109] = 178; hsh_t[110] = 179; hsh_t[111] = 180;
  hsh_t[112] = 181; hsh_t[113] = 182; hsh_t[114] = 183; hsh_t[115] = 184;
  hsh_t[116] = 185; hsh_t[117] = 186; hsh_t[118] = 187; hsh_t[119] = 188;
  hsh_t[120] = 189; hsh_t[121] = 190; hsh_t[122] = 191; hsh_t[123] = 68;
  hsh_t[124] = 68; hsh_t[125] = 68; hsh_t[126] = 68; hsh_t[127] = 68;
}



float hsh_char_rs(int c, float x, float y, float w, float kk) {
  String s;
  int i, j, D = 0;
  float rs, rc;
  float x1, x2, y1, y2;
  char a;

  if (w == 0) {
    rs = 0; rc = 1;
  } else {
    rs = sin(radians(w)); rc = cos(radians(w));
  }

  if (kk <= 0)
    return(0);

  if ((c <= 32) || (c > 127))
    return (HSH_SPACE * kk);

  s = hsh[hsh_t[c]];

  //s = "    1  9MWRMNV RRMVV RPSTS";

  if(s.length() >= 10) {
    hsh_char  = int(s.substring(0, 4));
    hsh_left  = (int) (s.charAt(8) - 'R');
    hsh_right = (int) (s.charAt(9) - 'R');
    D = hsh_right - hsh_left;

    i = 10;
    hsh_X1  = (int) (s.charAt(i) - 'R'); i ++;
    hsh_Y1  = (int) (s.charAt(i) - 'R'); i ++;
    x1 = kk * (hsh_X1 * rc - hsh_Y1 * rs);
    y1 = kk * (hsh_X1 * rs + hsh_Y1 * rc);
    plot.add(new plot_c('m', x + x1, y - y1));
    j = 2;

    while(i < s.length()) {
      a = s.charAt(i);

      switch(a) {
        case ' ':
          j = 0;
          i ++;
        break;
        default:
          if((a == 'R') && (j == 1)) {
            i ++;
            hsh_X1  = (int) (s.charAt(i) - 'R'); i ++;
            hsh_Y1  = (int) (s.charAt(i) - 'R'); i ++;
            x1 = kk * (hsh_X1 * rc - hsh_Y1 * rs);
            y1 = kk * (hsh_X1 * rs + hsh_Y1 * rc);
            plot.add(new plot_c('m', x + x1, y - y1));
          } else {
            hsh_X2  = (int) (s.charAt(i) - 'R'); i ++;
            hsh_Y2  = (int) (s.charAt(i) - 'R'); i ++;

            x2 = kk * (hsh_X2 * rc - hsh_Y2 * rs);
            y2 = kk * (hsh_X2 * rs + hsh_Y2 * rc);
            // line (x + kk * hsh_X1, y + kk * hsh_Y1, x + kk * hsh_X2, y + kk * hsh_Y2);
            // line (x + x1, y + y1, x + x2, y + y2);
            plot.add(new plot_c('l', x + x2, y - y2));

            hsh_X1 = hsh_X2;
            hsh_Y1 = hsh_Y2;
          }
        break;
      }
      j ++;
    }
  } // s.length() >= 10
  return(D * kk);
}




// ==========================================================================
// Drawbot Trace font
// ==========================================================================
void trc_setup () {
  int i, j;
  char a;
  String font_file = "../common/font_Drawbot_trace.txt";

  for (i = 0; i < 256; i ++)
    trc[i] = "";

  String lines[] = loadStrings(font_file);
  println("Drawbot Trace font: read " + lines.length + " lines from input file '" + font_file + "'.");
  for (i = 0; i < lines.length; i++) {
    String [] element = split(lines[i], ":");
    if (element.length > 1) {
      if (element[0].equals("") && element[1].equals("")) {
        j = int(':');
        trc[j] = element[2].toUpperCase();
      } else {
        j = int(element[0].charAt(0));
        trc[j] = element[1].toUpperCase();
      }
      //println(element[0] + " /// " + nf(j,1) + " /// " + lines[i]);
    }
  }
}

int trc_string (String s, int mX, int mY, int kk) {
  int i, x = 0;
  char a;

  for (i = 0; i < s.length(); i ++) {
    a = s.charAt(i);
    x = x + 2 + trc_char(a, mX + x * kk, mY, kk);
  }
  return(x);
}


int trc_char(int n, int mX, int mY, int kk) {
  int i = 0, init_move = 0;
  char a;
  int m = 0, mD = 0, mL = 0;
  int cX, cY;
  int scan_x = 0, max_x = 0;

  if ((n < 0) || (n > 255))
    return(0);

  String s = trc[n];

  if (s.length() == 0)
    return(0);

//  println (nf(n, 5));

  while (i < s.length()) {
    a = s.charAt(i);
    switch (m) {
      case 0:
        if (a == '-') {
          m = 2;
        } else {
          mD = byte(a) - 65;
          m = 1;
        }
      break;
      case 1:
        mL = byte(a) - 48;
//        println("L:" + nf(mD, 2) + "/" + nf(mL, 2));
        cX = mX + trc_dX[mD] * mL * kk;
        cY = mY + trc_dY[mD] * mL * kk;
        if (init_move == 0) {
          plot.add(new plot_c('m', mX, mY));
          init_move = 1;
        }
        plot.add(new plot_c('l', cX, cY));
        mX = cX;
        mY = cY;

        scan_x += trc_dX[mD] * mL;
        max_x = max(max_x, scan_x);
        m = 0;
      break;
      case 2:
        mD = byte(a) - 65;
        m = 3;
      break;
      case 3:
        mL = byte(a) - 48;
//        println("M:" + nf(mD, 2) + "/" + nf(mL, 2));
        mX = mX + trc_dX[mD] * mL * kk;
        mY = mY + trc_dY[mD] * mL * kk;
        plot.add(new plot_c('m', mX, mY));

        scan_x += trc_dX[mD] * mL;
        max_x = max(max_x, scan_x);
        m = 0;
        init_move = 1;
      break;
    }
    i ++;
  }

  if ((n == 'T') || (n == 'L'))
    max_x--;

  return(max_x);
}





// ==========================================================================
// Sticker gallery, 4x4
// ==========================================================================

//
// grid for stickers
//
int grid_Xmax = 4, grid_Ymax = 4;
int grid_X = 0, grid_Y = 0;
float grid_S = 5;
float grid_Xspan = 114.82;
float grid_Yspan = 72.39;


void gen_sticker_gallery(int mode) {
// X-mas only::String sticker_files = "DIY,MfK_DIY_90,Gingerbreadman_002,HackFFM_Logo_90,Xmas-tree_01,Camel,armadillo,deer_90,piggie_sihouette,elephant-animal-outline,seahorse_silhouette_90";
  String sticker_files = "DIY,Camel,armadillo,deer_90,piggie_sihouette,elephant-animal-outline,seahorse_silhouette_90";
  String[] list = split(sticker_files, ',');

  String hpgl_file = "";

  float gX0, gY0; // sticker origin
  float tx, ty; // temp x, y
  ArrayList sticker;
  sticker = new ArrayList();
  plot_c t_plot;

  int r;

  // add extreme corners
  sticker.add(new plot_c('x', 0, 0));
  sticker.add(new plot_c('x', grid_Xspan * grid_Xmax, grid_Yspan * grid_Ymax));

  // printable are of the stickers
  float print_sX = (grid_Xspan - 2 * grid_S);
  float print_sY = (grid_Yspan - 2 * grid_S);

  for (int iy = (grid_Ymax - 1); iy >= 0; iy --) {
    gY0 = grid_Yspan * (.5 + iy);
    for (int ix = 0; ix < grid_Xmax; ix ++) {
      gX0 = grid_Xspan * (.5 + ix);

      plot_remove(1);

      if (mode == 1) {
        p('m', gX0 - (print_sX / 2), gY0 - (print_sY / 2));
        p('l', gX0 + (print_sX / 2), gY0 - (print_sY / 2));
        p('l', gX0 + (print_sX / 2), gY0 + (print_sY / 2));
        p('l', gX0 - (print_sX / 2), gY0 + (print_sY / 2));
        p('l', gX0 - (print_sX / 2), gY0 - (print_sY / 2));
        hpgl_file = "Box";
      } else {
        switch (int(random(1,10))) {
          case 1 :
            gen_sample_text("DRAWBOT");
            break;
          case 111112 :
            hpgl_file = "../../samples/sticker/Snowflake-" + nf(int(random(1, 21)), 2) + ".hpgl";
            gen_hpgl(hpgl_file);
            if (random(1, 10) > 7)
              plot_mirror_X();
            break;
          default :
            r = int(random(0, list.length));
            hpgl_file = "../../samples/sticker/" + list[r] + ".hpgl";
            gen_hpgl(hpgl_file);
            if ((r > 0) && (random(1, 10) > 5))
              plot_mirror_X();
            break;
        }
      }
      get_min_max();

      t1 = (Xspan == 0) ? 1 : print_sX / Xspan;
      t2 = (Yspan == 0) ? 1 : print_sY / Yspan;

      float grid_scale = max(t1, t2); // first try - max scale

      if (((grid_scale * Xspan) > print_sX) || ((grid_scale * Yspan) > print_sY))
        grid_scale = min(t1, t2); // second try - min scale

      println("Gallery #" + nf(ix, 1) + "/" + nf(iy, 1) + " / " + hpgl_file + " / coords: " + nf(plot.size(),1));
      for(int i = 0; i < plot.size(); i ++) {
        t_plot = (plot_c) plot.get(i);
        tx = gX0 + (t_plot.X - X0) * grid_scale;
        ty = gY0 + (t_plot.Y - Y0) * grid_scale;
        sticker.add(new plot_c(t_plot.m, tx, ty));
      }
      plot_remove(0);
    }
  }
  plot = sticker;
}


void next_Grid() {
  grid_X ++;
  if (grid_X >= grid_Xmax) {
    grid_X = 0;
    grid_Y ++;
    if (grid_Y >= grid_Ymax)
      grid_Y = 0;
  }
}




void gen_RSS(String url, String url_title) {
  if (url == "")
    url = "http://www.heise.de/newsticker/heise-top-atom.xml";
  
  String accu = url_title + "^";
  
  XMLElement rss = new XMLElement(this, url);   
  // Get title of each element   
  println(rss);
  XMLElement[] titleXMLElements = rss.getChildren("entry/title");   //("channel/item/title");   
  for (int i = 0; i < min(titleXMLElements.length, 7); i++) {   
      String title = titleXMLElements[i].getContent();   
      println(i + ": " + title);
      accu += "#" + (i + 1) + " " + title + "^";
  }
  println(accu);
  gen_sample_text(accu);
}


// ==========================================================================
// virtual move to Grid
// ==========================================================================
void scale_to_Grid() {
  float over = 1.1;

  t1 = (Xspan == 0) ? 1 : grid_Xspan / Xspan;
  t2 = (Yspan == 0) ? 1 : grid_Yspan / Yspan;

  float grid_scale = max(t1, t2); // first try - max scale

  if (((grid_scale * Yspan) > grid_Yspan) || ((grid_scale * Xspan) > grid_Xspan))
    grid_scale = min(t1, t2); // second try - min scale


  float gX = over * grid_Xspan / grid_scale;
  float gY = over * grid_Yspan / grid_scale;

  float gX0 = X0 - (0.5 * gX) - grid_X * gX;
  float gY0 = Y0 - (0.5 * gY) - grid_Y * gY;

  float gX1 = X0 + (0.5 * gX) + (grid_Xmax - grid_X - 1) * gX;
  float gY1 = Y0 + (0.5 * gY) + (grid_Ymax - grid_Y - 1) * gY;

  p('x', gX0, gY0);
  p('x', gX1, gY1);
}


//
// Circle/elipse primitive
// x/y = center coords; rx, ry = radius in x/y direction
//
void bot_circle(float x, float y, float rx, float ry) {
  float w, d = max(8.0, 360. / (rx + ry) / 2);
  float x1, y1;
  char cc;

  for (w = .0; w <= 360.; w += d) {
    cc = (w == 0.) ? 'm' : 'l';

    x1 = x + rx * cos(radians(w));
    y1 = y + ry * sin(radians(w));
    p(cc, x1, y1);
  }
}


