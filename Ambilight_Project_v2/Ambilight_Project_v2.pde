static abstract class MODE {
  static final int CALIBRATION = 0;
  static final int PLAY  = 1;
  static final int PAUSE = 2;
  static final int CAMERAONLY = 3;
  static final int SCREENPOSITION = 4;
  static final int RESHAPEDSCREEN = 5;
}

ColorDetector cd;
int threshold, thresholdStep, mode;
PFont font;


void setup() {
  size(1000, 800, P2D);

  font = createFont("SourceCodePro-Regular.ttf", 13);
  textFont(font);

  mode = MODE.PAUSE;
  threshold = 10000;
  thresholdStep = 1000;

  cd = new ColorDetector(new WebCam(this, 1280, 720, 20), 11, 5, 3, 70.0/122.0);
}


void draw() {
  background(20);
  if (mode == MODE.PLAY) {
    cd.displayLedsColor();
  }
  else if (mode == MODE.PAUSE) {
    drawPauseMenu();
  }
  else if (mode == MODE.CALIBRATION) {
    cd.displayTvScreenMaskPreview(threshold);
    drawCalibrationMenu();
  }
  else if (mode == MODE.SCREENPOSITION) {
    cd.displayTvScreenPosition(color(255, 0, 0));
  }
  else if (mode == MODE.RESHAPEDSCREEN) {
    cd.displayReshapedTvScreen();
  }
  else if (mode == MODE.CAMERAONLY) {
    cd.displayCameraFeed();
  }
}


void keyPressed() {
  // Entering calibration mode
  if (key == 'c') {
    mode = MODE.CALIBRATION;
  } 
  // Decrease threshold step
  else if (key == '/' && mode == MODE.CALIBRATION) {
    if (thresholdStep >= 10) {
      thresholdStep /= 10;
    }
  } 
  // Increase threshold step
  else if (key == '*' && mode == MODE.CALIBRATION) {
    if (thresholdStep <= 1000) {
      thresholdStep *= 10;
    }
  } 
  // Increase threshold value
  else if (key == '+' && mode == MODE.CALIBRATION) {
    threshold += thresholdStep;
    if (threshold > 195075) {
      threshold = 195075;
    }
  } 
  // Decrease threshold value
  else if (key == '-' && mode == MODE.CALIBRATION) {
    threshold -= thresholdStep;
    if (threshold < 0) {
      threshold = 0;
    }
  }
  // Exit calibration mode
  else if ((int)key == 8 && mode == MODE.CALIBRATION) {
    mode = MODE.PAUSE;
  }
  // Bake the parameters of the color detector
  else if (key == 'b' && mode == MODE.CALIBRATION) {
    cd.bake(threshold);
    mode = MODE.PLAY;
  }
  // Display only the camera feed
  else if (key == '1') {
    mode = MODE.CAMERAONLY;
  }
  // Display the screen position
  else if (key == '2' && cd.isCalibrated()) {
    mode = MODE.SCREENPOSITION;
  }
  // Display the reshaped tv screen
  else if (key == '3' && cd.isCalibrated()) {
    mode = MODE.RESHAPEDSCREEN;
  }
  // Enter pause mode
  else if (key == 's') {
    mode = MODE.PAUSE;
  }
  // Enter play mode
  else if (key == 'p' && cd.isCalibrated()) {
    mode = MODE.PLAY;
  }
  else if (key == '9') {
    saveFrame("screenShot_##.jpeg");
  }
}


void drawCalibrationMenu() {
  textAlign(LEFT);
  fill(255);
  text("/: decrease step size", 10, 20);
  text("*: increase step size", 10, 40);
  text("-: decrease threshold by step size", 10, 60);
  text("+: increase threshold by step size", 10, 80);
  text("Back space: cancel", 10, 100);
  textAlign(RIGHT);
  text("Step size: " + thresholdStep, width - 10, 20);
  text("Thershold value: " + threshold, width - 10, 40);
  text("b: Bake", width - 10, 60);
}


void drawPauseMenu() {
  textAlign(LEFT);
  fill(255);
  text("You are currently in pause mode.", 10, 20);
  text("This is the list of all the possible actions: ", 10, 50);
  text("c: enter Calibration mode", 10, 90);
  text("s: enter Pause (Stop) mode", 10, 110);
  text("1: enter 1st debug mode - display camera feed only", 10, 130);

  if (cd.isCalibrated()) {
    fill(0, 255, 0);
    text("YOUR SYSTEM IS CALIBRATED!", 10, 200);
    fill(255);
  } else {
    fill(255, 0, 0);
    text("TO ACCESS THE RED FUNCTIONALITIES, YOU FIRST NEED TO CALIBRATE THE SYSTEM", 10, 200);
  }

  text("p: enter Play mode", 10, 70);
  text("2: enter 2nd debug mode - display the location of the tv screen", 10, 150);
  text("3: enter 3rd debug mode - display the isolated and reshaped screen", 10, 170);
}
