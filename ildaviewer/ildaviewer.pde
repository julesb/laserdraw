import oscP5.*;
import netP5.*;
import java.io.File;
import java.util.Collections;

OscP5 oscP5;
NetAddress network;
OscProperties oscProps;

IldaFile ildaFile;
IldaFrame currentFrame;
int currentFrameIdx = 0;
int prevFrameIdx;

String ildaPath;
String ildaFilename;
static final int POINTS_PER_SEC = 12000;

File[] dataFiles;
ArrayList<String> ildaFilenames = new ArrayList();
int currentIldaFileIdx = 0;
int prevFileChangeTime = 0;
int fixedFrameRate = 30;

float[] oscBufferX;
float[] oscBufferY;
float[] oscBufferBl;
float[] oscBufferR;
float[] oscBufferG;
float[] oscBufferB;


int autoChangeInterval = 2000; // ms
boolean autoChangeEnabled = false;
boolean autoChangeRandom = true;
boolean previewMode = false;
boolean constantPPS = true;
boolean showInfo = true;
boolean showBlankLines = true;
boolean oscSendEnabled = false;


void setup() {
  size(1200, 1200);
  frameRate(30);

  oscProps = new OscProperties();
  network = new NetAddress("127.0.0.1", 12000);
  oscProps.setRemoteAddress(network);
  oscProps.setDatagramSize(4096);
  oscP5 = new OscP5(this, oscProps);

  if (args != null && args.length == 1) {
    ildaFilename = args[0];
    autoChangeEnabled = false;
    previewMode = true;
    constantPPS = false;
    oscSendEnabled = false;
    println("arg filename:" + ildaFilename);
  } else {
    File datadir = new File(dataPath(""));
    ildaPath = datadir.getAbsolutePath();
    println("ilda path:" + ildaPath);
    dataFiles = datadir.listFiles();
    for (int i = 0; i < dataFiles.length; i++) {
      String baseName = dataFiles[i].getName();
      if (baseName.endsWith(".ild")) {
        println(baseName);
        ildaFilenames.add(baseName);
      }
    }
    Collections.sort(ildaFilenames);
    ildaFilename = ildaFilenames.get(0);
  }

  println("sketchpath: " + sketchPath());
  if (previewMode) {
    ildaFile  = new IldaFile(ildaFilename, ildaFilename);
  } else {
    ildaFile  = new IldaFile(dataPath(ildaFilename), ildaFilename);
  }

  prevFileChangeTime = millis();
  if (ildaFile != null && ildaFile.frameCount > 0) {
    currentFrame = ildaFile.frames.get(0);
    oscSendFrame(currentFrame);
  }

  blendMode(ADD);
  textSize(32);
}



void draw() {
  background(0);
  int t = millis();

  if (autoChangeEnabled
    && currentFrameIdx == 0
    && t - prevFileChangeTime > autoChangeInterval) {
    if (autoChangeRandom) {
      loadRandom();
    } else {
      loadNext();
    }
    prevFileChangeTime = t;
    //currentFrameIdx = 0;
  }

  if (ildaFile != null && ildaFile.frames != null && ildaFile.frameCount > 0) {
    currentFrame = (IldaFrame)ildaFile.frames.get(currentFrameIdx);

    if (constantPPS) {
      float newfr = (float)POINTS_PER_SEC / currentFrame.pointCount;
      if (newfr > 0) {
        frameRate(newfr);
      }
    }
    drawIldaFrame(currentFrame);

    if (oscSendEnabled && prevFrameIdx != currentFrameIdx) {
      oscSendFrame(currentFrame);
    }
    prevFrameIdx = currentFrameIdx;
    currentFrameIdx++;
    currentFrameIdx %= ildaFile.frameCount;
  }
  if (showInfo) {
    drawInfo(20, 40);
  }
}


void keyPressed() {
  if (previewMode) {
    return;
  }
  if (key == CODED) {
    switch (keyCode) {
    case LEFT:
      loadPrev();
      break;
    case RIGHT:
      loadNext();
      break;
    }
  }
}

void keyTyped() {
  println("key: " + key);
  switch(key) {
    case 'a':
      autoChangeEnabled = !autoChangeEnabled;
      println("auto change: " + autoChangeEnabled);
      break;
    case 'c':
      constantPPS = !constantPPS;
      if (!constantPPS) {
        frameRate(fixedFrameRate);
      }
      println("constant PPS: " + constantPPS);
      break;
    case 'i':
      showInfo = !showInfo;
      break;
    case 'b':
      showBlankLines = !showBlankLines;
      break;
    case 'o':
      oscSendEnabled = !oscSendEnabled;
      break;
  }
}


void load(int fileIdx) {
  String shortname = ildaFilenames.get(fileIdx);
  ildaFilename = ildaPath + "/" + shortname;
  ildaFile  = new IldaFile(ildaFilename, shortname);
  currentFrameIdx = 0;
}
void loadNext() {
  currentIldaFileIdx++;
  currentIldaFileIdx %= ildaFilenames.size();
  load(currentIldaFileIdx);
}
void loadPrev() {
  currentIldaFileIdx--;
  currentIldaFileIdx = currentIldaFileIdx < 0? ildaFilenames.size()-1: currentIldaFileIdx;
  load(currentIldaFileIdx);
}
void loadRandom() {
  currentIldaFileIdx = (int)(random(1.0)*ildaFilenames.size());
  load(currentIldaFileIdx);
}


void drawInfo(int x, int y) {
  int lineheight = 32;
  fill(128);
  text("file: " +ildaFile.name, x, y + lineheight*1);
  text("fps: " + String.format("%.1f", frameRate), x, y + lineheight*2);
  text("pps: " + POINTS_PER_SEC / 1000 + "k", x, y + lineheight*3);
  text("auto: " + autoChangeEnabled, x, y + lineheight*4);
  if (oscSendEnabled) {
    fill(192, 0, 0);
  } else {
    fill(128);
  }
  text("OSC: " + oscSendEnabled, x, y + lineheight*5);

  drawProgress(0, 0, width, 2);
}


void drawIldaFrame(IldaFrame frame) {
  if (frame == null) {
    println("ERROR: frame is null");
    return;
  }
  if (frame.points == null) {
    println("ERROR: frame.points is null");
    return;
  }
  pushMatrix();
  translate(width/2, height/2);

  for (int pidx = 0; pidx < frame.points.size()-1; pidx++) {
    IldaPoint p1 =frame.points.get(pidx);
    IldaPoint p2 =frame.points.get(pidx+1);
    float x1 = (float)p1.x / Short.MAX_VALUE * (width/2);
    float y1 = (float)p1.y / Short.MAX_VALUE * (height/2) * -1;
    float x2 = (float)p2.x / Short.MAX_VALUE * (width/2);
    float y2 = (float)p2.y / Short.MAX_VALUE * (height/2) * -1;

    noFill();
    if (p1.blank) {
      if (showBlankLines) {
        strokeWeight(1);
        stroke(64, 64, 64);
      } else {
        noStroke();
      }
    } else {
      int[] rgb = rgbIntensity(p1.rgb, 0.4);
      strokeWeight(6);
      stroke(rgb[0], rgb[1], rgb[2]);
      //stroke(255);
    }

    line(x1, y1, x2, y2);
  }
  popMatrix();
}

void drawProgress(int x, int y, int w, int h) {
  int numFrames = ildaFile==null? 0 : ildaFile.frameCount;
  if (numFrames == 0) {
    return;
  }
  strokeWeight(h);
  stroke(64);
  //line(x, y, x+w, y);

  float t = ((float) (1+currentFrameIdx)) / numFrames;
  float x2 = x + t * w;

  stroke(0, 255, 0);
  line(x, y, x2, y);
}


int[] rgbIntensity(int[] rgb, float intensity) {
  int[] ret = {
    (int)(rgb[0]*intensity), 
    (int)(rgb[1]*intensity), 
    (int)(rgb[2]*intensity)
  };
  return ret;
}


void oscSendFrame(IldaFrame frame) {
  int numpoints = frame.points.size();
  if (oscBufferX == null || numpoints != oscBufferX.length) {
    oscBufferX  = new float[numpoints];
    oscBufferY  = new float[numpoints];
    oscBufferBl = new float[numpoints];
    oscBufferR  = new float[numpoints];
    oscBufferG  = new float[numpoints];
    oscBufferB  = new float[numpoints];
  }
  for (int i=0; i< numpoints; i++) {
    IldaPoint p = frame.points.get(i);
    oscBufferX[i]  =  p.x / (float)Short.MAX_VALUE;
    oscBufferY[i]  =  p.y / (float)Short.MAX_VALUE;
    oscBufferBl[i] = p.blank? 1.0 : 0.0;
    oscBufferR[i]  = (float)p.rgb[0] / 255.0;
    oscBufferG[i]  = (float)p.rgb[1] / 255.0;
    oscBufferB[i]  = (float)p.rgb[2] / 255.0;
  }

  OscMessage pointsxMessage = new OscMessage("/pointsx");
  OscMessage pointsyMessage = new OscMessage("/pointsy");
  OscMessage blankMessage   = new OscMessage("/blank");
  OscMessage redMessage     = new OscMessage("/red");
  OscMessage greenMessage   = new OscMessage("/green");
  OscMessage blueMessage    = new OscMessage("/blue");
  pointsxMessage.add(oscBufferX);
  pointsyMessage.add(oscBufferY);
  blankMessage.add(oscBufferBl);
  redMessage.add(oscBufferR);
  greenMessage.add(oscBufferG);
  blueMessage.add(oscBufferB);
  oscP5.send(pointsxMessage, network);
  oscP5.send(pointsyMessage, network);
  oscP5.send(blankMessage, network);
  oscP5.send(redMessage, network);
  oscP5.send(greenMessage, network);
  oscP5.send(blueMessage, network);
}
