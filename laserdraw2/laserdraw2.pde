import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress network;

//int NUMPOINTS = 300;

//float[] pointsX = new float[NUMPOINTS];
//float[] pointsY = new float[NUMPOINTS];
//int[] pointIntensity = new int[NUMPOINTS];

static final int LASER_FRAME_RATE = 60;
static final int SAMPLE_RATE = 44100;
static final int SAMPLES_PER_FRAME = SAMPLE_RATE / LASER_FRAME_RATE; 

ArrayList<ArrayList> paths = new ArrayList();
//int currentPathIdx = -1;

float[] pointsX;
float[] pointsY;  

PVector closestPoint = new PVector(0,0);

//int pointidx = 0;

PVector mousePos = new PVector(mouseX, mouseY);


void setup() {
  size(1024,1024);
  frameRate(60);
  oscP5 = new OscP5(this,12000);
  network = new NetAddress("127.0.0.1",12000);
}


void update () {
  
  if(pointsX != null && pointsY != null) {
  
    int idx = 0;
    for(int pidx = 0; pidx < paths.size(); pidx++) {
      ArrayList path = paths.get(pidx);
      for (int vidx = 0; vidx < path.size(); vidx++) {
        PVector p = (PVector)path.get(vidx);
        if (idx < pointsX.length) {
          pointsX[idx] = p.x / width*2
                       + (float)Math.sin(frameCount * 0.05 + p.x) * 0.03;
          pointsY[idx] = p.y / height*2
                       + (float)Math.cos(frameCount * 0.0523 + p.y) * 0.03;
        }
        idx++;
      }
    }
    pointsX[pointsX.length-1] = pointsX[0];  
    pointsY[pointsY.length-1] = pointsY[0]; 

  }
}


void drawBeamPath() {
  if(pointsX == null || pointsY == null) {
    return; 
  }
  //scale(width/2);
  strokeWeight(2);
  stroke(0,0,255);
  for (int i=0; i < pointsX.length-1; i++) {
    line(pointsX[i]*width/2, pointsY[i]*height/2, pointsX[i+1]*width/2, pointsY[i+1]*height/2);
  
  }
  int lastidx = max(pointsX.length - 2, 0);
  int dotsize = 10;
  //strokeWeight(5);
  stroke(0, 255, 0);
  fill(0, 255, 0);
  
  ellipse(pointsX[0]*width/2, pointsY[0]*height/2, dotsize, dotsize);
  
  stroke(255, 0, 0);
  fill(255, 0, 0);
  ellipse(pointsX[lastidx]*width/2, pointsY[lastidx]*height/2, dotsize, dotsize);
}

void draw() {
  //update();
  background(0);
  
/*  
  if (mousePressed && mouseButton == LEFT) {
    if (currentPathIdx >= 0 && mouseX != pmouseX && mouseY != pmouseY) {
       paths.get(currentPathIdx).add(new PVector(mouseX - width/2, mouseY - height/2));
    }
    
  }
*/  
  if(pointsX != null && pointsY != null) {
    OscMessage pointsxMessage = new OscMessage("/pointsx");
    OscMessage pointsyMessage = new OscMessage("/pointsy");
    pointsxMessage.add(pointsX);
    pointsyMessage.add(pointsY);
    oscP5.send(pointsxMessage, network);
    oscP5.send(pointsyMessage, network);
  }
  
  translate(width/2, height/2);

  stroke(0,255,0);
  line(mouseX-width/2, mouseY-height/2, closestPoint.x, closestPoint.y);

  stroke(255);
    
  for(int pidx = 0; pidx < paths.size(); pidx++) {
    ArrayList path = paths.get(pidx);
    for (int vidx = 0; vidx < path.size()-1; vidx++) {
      PVector v1 = (PVector)path.get(vidx);
      PVector v2 = (PVector)path.get(vidx+1);
      line(v1.x, v1.y, v2.x, v2.y);
    }
  }
  
  drawBeamPath();
}

void mouseMoved() {
  mousePos.x = mouseX-width/2;
  mousePos.y = mouseY-height/2;
 
  if (paths.size() > 0) {
    int[] idxs = findclosestpoint(mousePos);
    closestPoint = (PVector)paths.get(idxs[0]).get(idxs[1]);
  }
}

void mouseClicked() {
  if (mouseButton == LEFT) {
    if (paths.size() == 0) {
      paths.add(new ArrayList());
      paths.get(0).add(new PVector(mousePos.x, mousePos.y));
    }
    else {
      int[] closest = findclosestpoint(mousePos);
      int pidx = closest[0];
      int vidx = closest[1];
      PVector newPoint = new PVector(mousePos.x, mousePos.y);
      paths.get(pidx).add(newPoint);
      closestPoint = newPoint;
    }
  }
  
  updatePoints();
  
}



void mousePressed() {
  if (mouseButton == RIGHT) {
    paths = new ArrayList();
    //currentPathIdx = -1;
  }
//  else {
//    paths.add(new ArrayList());
//    currentPathIdx++;
//  }
}

void mouseReleased() {
  //int numpoints = getpointcount(paths);
    //println("points:" + numpoints);
    //pointsX = new float[numpoints];
    //pointsY = new float[numpoints];  

/*  
    int idx = 0;
    for(int pidx = 0; pidx < paths.size(); pidx++) {
      ArrayList path = paths.get(pidx);
      for (int vidx = 0; vidx < path.size()-1; vidx++) {
        PVector p = (PVector)path.get(vidx);

        pointsX[idx] = p.x / width*2
                     + (float)Math.sin(frameCount * 0.2 + p.x) * 1.0;
        pointsY[idx] = p.y / height*2
                     + (float)Math.cos(frameCount * 0.2 + p.y) * 1.0;
        idx++;
      }
    }


  if (numpoints > 0) {
    OscMessage pointsxMessage = new OscMessage("/pointsx");
    OscMessage pointsyMessage = new OscMessage("/pointsy");
    pointsxMessage.add(pointsX);
    pointsyMessage.add(pointsY);
    oscP5.send(pointsxMessage, network);
    oscP5.send(pointsyMessage, network);
  }
*/
}


void updatePoints() {
  int numpoints = getpointcount(paths);
  println("points:" + numpoints);

  pointsX = new float[numpoints+1];
  pointsY = new float[numpoints+1];  

  
  int idx = 0;
  for(int pidx = 0; pidx < paths.size(); pidx++) {
    ArrayList path = paths.get(pidx);
    for (int vidx = 0; vidx < path.size(); vidx++) {
      PVector p = (PVector)path.get(vidx);

      pointsX[idx] = p.x / width*2;
      pointsY[idx] = p.y / height*2;

      //pointsX[idx] = p.x / width*2
      //             + (float)Math.sin(frameCount * 0.2 + p.x) * 1.0;
      //pointsY[idx] = p.y / height*2
      //             + (float)Math.cos(frameCount * 0.2 + p.y) * 1.0;
      idx++;
    }
  }
  pointsX[numpoints] = pointsX[0];  
  pointsY[numpoints] = pointsY[0];
}


/* incoming osc message are forwarded to the oscEvent method. */
/*
void oscEvent(OscMessage theOscMessage) {
  print("### received an osc message.");
  print(" addrpattern: "+theOscMessage.addrPattern());
  println(" typetag: "+theOscMessage.typetag());
}
*/

// Find [pathidx, pointindex, distance] of closest point to p
int[] findclosestpoint(PVector p) {
  float closestdist = 9999999.0;
  int[] ret = new int[2];
  for(int pidx = 0; pidx < paths.size(); pidx++) {
    ArrayList path = paths.get(pidx);
    for (int vidx = 0; vidx < path.size(); vidx++) {
      PVector test = (PVector)path.get(vidx);
      float dist = p.dist(test);
      if (dist < closestdist) {
        closestdist = dist;
        ret[0] = pidx;
        ret[1] = vidx;
      }
    }
  }
  return ret;
}


int getpointcount(ArrayList paths) {
  int count = 0;
  for (int i = 0; i < paths.size(); i++) {
    count += ((ArrayList)paths.get(i)).size();
  }
  return count;
}

float cosinelerp(float y1,float y2, float mu) {
   float mu2 = (1.0-cos(mu*PI))* 0.5;
   return(y1*(1.0-mu2)+y2*mu2);
}
