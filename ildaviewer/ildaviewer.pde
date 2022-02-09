import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress network;

IldaFile ildaFile;
IldaFrame currentFrame;
int currentFrameIdx = 0;


String ildaFilename = "ildatest.ild";
static final boolean DRAW_BLANK_LINES = true;

void setup() {
  size(1200,1200);
  frameRate(25);
  oscP5 = new OscP5(this,12000);
  network = new NetAddress("127.0.0.1",12000);
  
  println("sketchpath: " + sketchPath());
  ildaFile  = new IldaFile(dataPath(ildaFilename));
  if (ildaFile != null && ildaFile.frameCount > 0) {
    print("Loaded " + ildaFilename + " (frames=)" + ildaFile.frameCount);
    currentFrame = ildaFile.frames.get(0);
  }
  
  blendMode(ADD);
}



void draw() {
  background(0);

  if (ildaFile != null && ildaFile.frames != null && ildaFile.frameCount > 0) {
    currentFrame = (IldaFrame)ildaFile.frames.get(currentFrameIdx++ % ildaFile.frameCount);
    drawIldaFrame(currentFrame);
  }
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

  translate(width/2, height/2);

  for (int pidx = 0; pidx < frame.points.size()-1; pidx++) {
    IldaPoint p1 =frame.points.get(pidx);
    IldaPoint p2 =frame.points.get(pidx+1);
    float x1 = (float)p1.x / Short.MAX_VALUE * (width/2);
    float y1 = (float)p1.y / Short.MAX_VALUE * (height/2) * -1;
    float x2 = (float)p2.x / Short.MAX_VALUE * (width/2);
    float y2 = (float)p2.y / Short.MAX_VALUE * (height/2) * -1;
    
    noFill();
    if(p1.blank) {
      if (DRAW_BLANK_LINES) {
        strokeWeight(1);
        stroke(64,64,64);
      }
      else {
        noStroke();
      }
    }
    else {
      int[] rgb = rgbIntensity(p1.rgb, 0.25);
      strokeWeight(6);
      stroke(rgb[0], rgb[1], rgb[2]);
    }
    
    line(x1, y1, x2, y2);
  }
}


int[] rgbIntensity(int[] rgb, float intensity) {
  int[] ret = {
    (int)(rgb[0]*intensity),
    (int)(rgb[1]*intensity),
    (int)(rgb[2]*intensity)
  };
  return ret;
}

/*
void sendOsc() {
  if(pointsX != null && pointsY != null) {
    OscMessage pointsxMessage = new OscMessage("/pointsx");
    OscMessage pointsyMessage = new OscMessage("/pointsy");
    pointsxMessage.add(pointsX);
    pointsyMessage.add(pointsY);
    oscP5.send(pointsxMessage, network);
    oscP5.send(pointsyMessage, network);
  }
}
*/
