/*
  Drawbot
  https://hackerspace-ffm.de/wiki/index.php?title=Drawbot@MfK

  Screen setup and drawing
*/



//
// screen coordinate system
// measured in pixel, 0/0 is defined on left bottom edge
//
float scr_X0, scr_Y0;             // origin of coordinate system, middle
float scr_Xmin, scr_Xmax, scr_Ymin, scr_Ymax;
float scr_Xspan, scr_Yspan;       // span
float scr_scale;                  // scaler

float mX = scr_X0, mY = scr_Y0, cX, cY; // memories, last pos, and current

//
// initialize screen
//
void scr_setup() {
  textFont(myFont);
  size(1000, 650);
  background (224);
  stroke(0, 0, 255);
  fill(0, 0, 128);

  img_logo = loadImage("../common/Logo_HSFFM.png");
  img_osh  = loadImage("../common/Logo_OSHW.png");

  // screen min/max/span
  scr_Xmin = (float) 200;
  scr_Xmax = (float) width - 1;
  scr_Ymin = (float) 72;
  scr_Ymax = (float) height - 1;

  scr_Xspan = scr_Xmax - scr_Xmin;
  scr_Yspan = scr_Ymax - scr_Ymin;
}



//
// normalize screen
// get scaling to display current drawing on screen
//
void scr_normalize() {
  // get plot min and max coordinates
  int i;
  float t1, t2; // temporary vars

  get_min_max();

  t1 = (Xspan == 0) ? 1 : scr_Xspan / Xspan;
  t2 = (Yspan == 0) ? 1 : scr_Yspan / Yspan;

  scr_scale = max(t1, t2); // first try - max scale

  if (((scr_scale * Yspan) > scr_Yspan) || ((scr_scale * Xspan) > scr_Xspan))
    scr_scale = min(t1, t2); // second try - min scale

  // center image coordinates
  scr_X0 = scr_Xmin + (scr_Xspan / 2);
  scr_Y0 = scr_Ymin + (scr_Yspan / 2);
}



//
// info screen overlay
// display various infods for the bot, drawing, and debug
//
void scr_info_screen() {
  int x0 = 10, x1 = 120, x2 = width / 2 - 40; x3 = width - 200;
  int y1 = 100, y2 = y1 + 20, y3 = y2 + 30, y4 = y3 + 20;
  int section_height = 120;

  int lines = 0, moves = 0, i, coords = plot.size();
  float mx, my, len, path_len = 0, line_len = 0, move_len = 0;
  plot_c t_plot;

  if (coords > 0) {
    t_plot = (plot_c) plot.get(0);
    mx = t_plot.X;
    my = t_plot.Y;
    for(i = 0; i < plot.size(); i ++) {
      t_plot = (plot_c) plot.get(i);
      len = sqrt(sq(t_plot.X - mx) + sq(t_plot.Y - my));

      if (t_plot.m == 'm') {
        moves ++;
        move_len += len;
      }
      if (t_plot.m == 'l') {
        lines ++;
        line_len += len;
      }

      path_len += len;
      mx = t_plot.X;
      my = t_plot.Y;
    }
  }

  pushStyle();
  stroke(64);
  scr_DRAWBOT();

  fill(255, 255, 255, 192);
  stroke(255);
  rect(scr_Xmin, scr_Ymin, scr_Xspan, scr_Yspan);

  fill(255, 0, 0);

  text("Plot:", x0, y1);

  text("Xmin: " + nfp(Xmin, 1, 2), x1, y1);
  text("Xmax: " + nfp(Xmax, 1, 2), x1, y2);
  text("Ymin: " + nfp(Ymin, 1, 2), x2, y1);
  text("Ymax: " + nfp(Ymax, 1, 2), x2, y2);

  text("bot_scale: " + nf(bot_scale, 1, 5), x3, y1);

  if (Yspan > 0);       // span
    text("X / Y = " + nf(100 * Xspan / Yspan, 1, 2) + " %", x3, y2);

  y1 += section_height; y2 += section_height; y3 += section_height; y4 += section_height;

  text("Drawbot:", x0, y1);

  text("Xmin: " + nfp(bot_scale * (Xmin - X0), 1, 1), x1, y1);
  text("Xmax: " + nfp(bot_scale * (Xmax - X0), 1, 1), x1, y2);
  text("Ymin: " + nfp(bot_scale * (Ymin - Y0), 1, 1), x2, y1);
  text("Ymax: " + nfp(bot_scale * (Ymax - Y0), 1, 1), x2, y2);

  text("bot_Xorigin: " + nfp(bot_Xo, 1, 1), x1, y3);
  text("bot_X0: " + nfp(bot_X0, 1, 1), x1, y4);
  text("bot_Yorigin: " + nfp(bot_Yo, 1, 1), x2, y3);
  text("bot_Y0: " + nfp(bot_Y0, 1, 1), x2, y4);

  text("X usage: " + nf(100 * bot_scale * (Xmax - Xmin) / (bot_Xmax - bot_Xmin), 1, 2) + " %", x3, y1);
  text("Y usage: " + nf(100 * bot_scale * (Ymax - Ymin) / (bot_Ymax - bot_Ymin), 1, 2) + " %", x3, y2);

  text("Area X: " + nfp(bot_Xmin, 1, 1) + " / " + nfp(bot_Xmax, 1, 1), x3, y3);
  text("Area Y: " + nfp(bot_Ymin, 1, 1) + " / " + nfp(bot_Ymax, 1, 1), x3, y4);


  y1 += section_height; y2 += section_height; y3 += section_height; y4 += section_height;

  text("Statistics:", x0, y1);

  text("Coords: " + nf(coords, 1), x1, y1);
  text("Undo: " + nf(plot_undo.size(), 1), x1, y2);
  text("bot_ID: " + bot_ID, x1, y3);
  text("bot_init_string: " + bot_init_string, x1, y4);
  text("bot_ff_string: " + bot_ff_string, x2, y4);
  text("bot_ramp_string: " + bot_ramp_string, x3, y4);

  text("Moves: " + nf(moves, 1), x2, y1);
  text("Lines: " + nf(lines, 1), x2, y2);
  if (moves > 0)
    text("Lines per move: " + nf((float) lines / (float) moves, 1, 1), x2, y3);

  text("Move length: " + nf(move_len * bot_scale / 1000, 1, 3) + " m",  x3, y1);
  text("Line length: " + nf(line_len * bot_scale / 1000, 1, 3) + " m",  x3, y2);
  text("Path length: " + nf(path_len * bot_scale / 1000, 1, 3) + " m",  x3, y3);

  popStyle();
}

//
// redraw screen
//
void scr_redraw(int draw_limit) {
  plot_c t_plot = (plot_c) plot.get(0);
  float mX = scr_X0, mY = scr_Y0, cX, cY; // memories, last pos, and current
  float bot_mX = 0, bot_mY = 0, bot_cX, bot_cY; // bot test - memories, last pos, and current
  int i, j;
  int col;

  image (img_logo, 14, 6);
  image (img_osh, width - 84, 4);

  pushStyle();
  stroke(64);
  scr_DRAWBOT();

  fill(64);
  text(bot_ID, width / 2 + 200, 18);

  stroke(32);
  for (i = 0; i < 4; i ++)
    for (j = 0; j < 4; j ++) {
      if ((i == grid_X) && (j == grid_Y))
        fill(32, 192, 32);
      else
        fill(160);
      rect(100 + i * 12, 50 - j * 8, 10, 6);
    }

  fill(255);
  stroke(255);
  rect(scr_Xmin, scr_Ymin, scr_Xspan, scr_Yspan);

  stroke(0, 0, 255);

  if ((draw_limit == 0) || (draw_limit > plot.size()))
    draw_limit = plot.size();

  for (i = 0; i < plot.size(); i ++) {
    col = (i * 255 / plot.size());
    if (i < draw_limit)
      stroke(0, 255 - col, col);
    else
      stroke(255, 192, 0);

    t_plot = (plot_c) plot.get(i);
    cX = scr_X0 + scr_scale * (t_plot.X - X0);
    cY = scr_Y0 - scr_scale * (t_plot.Y - Y0);

    if (t_plot.m == 'l')
      line(mX, mY, cX, cY);

    mX = cX;
    mY = cY;
  }

  popStyle();
}


//
// DRAWBOT logo for the syreen
//
void scr_DRAWBOT() {
  int kk = 6;
  int mX = width / 2 - 200, mY = 66;
  int cX, cY;

  int[] trc_dX = { +1, +1,  0, -1, -1, -1,  0, +1};
  int[] trc_dY = {  0, +1, +1, +1,  0, -1, -1, -1};

  String s = "05122632456961-12021124314266"; // D
  s += "-72-050224027163022431112232456961-12-240211314262"; // R
  s += "-76-0102240364022832435268-12-24032131415161"; // A
  s += "-74-0372021171021228426751312742675131274268"; // W
  s += "-72-09-0105122231112232456961-120211314262-240211314262"; // B
  s += "-74-037203122632435266-11-017101112431415164"; // O
  s += "-73-060228032248620368"; // T

  int i = 0;
  char a;
  int m = 0, mD = 0, mL = 0;

  while (i < s.length()) {
    a = s.charAt(i);
    switch (m) {
      case 0:
        if (a == '-') {
          m = 2;
        } else {
          mD = byte(a) - 48;
          m = 1;
        }
      break;
      case 1:
        mL = kk * (byte(a) - 48);
        cX = mX + trc_dX[mD] * mL;
        cY = mY - trc_dY[mD] * mL;
        line(mX, mY, cX, cY);
        line(mX + 1, mY, cX + 1, cY);
        mX = cX;
        mY = cY;
        m = 0;
      break;
      case 2:
        mD = byte(a) - 48;
        m = 3;
      break;
      case 3:
        mL = kk * (byte(a) - 48);
        mX = mX + trc_dX[mD] * mL;
        mY = mY - trc_dY[mD] * mL;
        m = 0;
      break;
    }
    i ++;
  }
}



//
// analysis of angular accelerations in the plot array
// 2014-02-13 ramps
//
void analyze_accelerations_on_screen() {
  plot_c t_plot;
  
  float mx = 0, my = 0;  // origin --- accually not correct (middle of plot area?)
  float dx = 0, dy = 0;  // delta coords
  float a0 = 0, a1 = 0, da = 0;  // angles

  float a_screen_x, a_screen_y, a_screen_y0;
  float l1, l0 = max(1, sqrt(sq(Xmax-Xmin) + sq(Ymax-Ymin)));
  
  println("l0: "+l0);
  a_screen_y0 = scr_Ymin + scr_Yspan / 2;

  stroke(192);

  // guide lines; 45°
  for (float f = -PI; f <= PI; f+= (PI / 4)) {
    a_screen_y = a_screen_y0 - ((scr_Yspan / 2) * (f / PI));
    line (0, a_screen_y, width, a_screen_y);
  }

  for (int i = 0; i < plot.size(); i ++) {
    t_plot = (plot_c) plot.get(i);
    dx = t_plot.X - mx;
    dy = t_plot.Y - my;
    a1 = atan2(dy, dx);
    da = a1 - a0;
    if (da < -PI)  da += (TWO_PI); // normalize turnovers
    if (da >  PI)  da -= (TWO_PI);
    
    // length
    l1 = sqrt(sq(dx) + sq(dy));
    l1 = (l1 / l0) * 255;
    
    a_screen_x = (width * i) / plot.size();
    a_screen_y = a_screen_y0 - ((scr_Yspan / 2) * (da / PI));
    
    if(t_plot.m == 'm')
      stroke(0, 128, 255);
    else
      stroke(255 - l1, 128 + l1 / 2, 0);

    line(a_screen_x, a_screen_y0, a_screen_x, a_screen_y);
    
    mx = t_plot.X;
    my = t_plot.Y;
    a0 = a1;
  }
}




void mouseClicked() {
  if (mouseX < 200) {
     println (mouseX + " / " + mouseY);
     
    String hpgl_file;
    background (224); plot_remove(1);
    String demo_files = "armadillo,Black_Horse,Camel,piggie_sihouette,seahorse_silhouette,unicorn,deer_matt_todd_01,turtle-outline,elephant-animal-outline,sportscar-outline,MfK_Logo_001,DIY";
    String[] list = split(demo_files, ',');
    hpgl_file = "../../drawings/samples/" + list[int(random(0, list.length))] + ".hpgl";
    gen_hpgl(hpgl_file);
    scr_normalize(); bot_normalize(); scr_redraw(0);

    pushStyle();
    textAlign(CENTER, CENTER);
    ellipseMode(CENTER);
    
    for (int i = 0; i < 8; i ++) {
      float y = scr_Ymin + int(((i * 2 + 1) * scr_Yspan) / (2 * 8));
      noStroke(); fill(192);
      rect (10, y - 20, 80, 42);
      noStroke(); fill(128);
      text("Sym.\nTree", 50, y);
    }
    pushStyle();

  }
  

}
