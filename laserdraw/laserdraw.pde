import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress network;

//int NUMPOINTS = 300;

//int[] pointsX = new int[NUMPOINTS];
//int[] pointsY = new int[NUMPOINTS];
//int[] pointIntensity = new int[NUMPOINTS];

static final int LASER_FRAME_RATE = 60;
static final int SAMPLE_RATE = 44100;
static final int SAMPLES_PER_FRAME = SAMPLE_RATE / LASER_FRAME_RATE; 

ArrayList<ArrayList> paths = new ArrayList();
int currentPathIdx = -1;

float[] pointsX;
float[] pointsY;  


//int pointidx = 0;




void setup() {
  size(1024,1024);
  frameRate(60);
  oscP5 = new OscP5(this,12000);
  network = new NetAddress("127.0.0.1",12000);
}


void draw() {
  background(0);
  
  
  if (mousePressed && mouseButton == LEFT) {
    if (currentPathIdx >= 0 && mouseX != pmouseX && mouseY != pmouseY) {
       paths.get(currentPathIdx).add(new PVector(mouseX - width/2, mouseY - height/2));
    }
    
  }
  
  stroke(255);
  
  translate(width/2, height/2);
  for(int pidx = 0; pidx < paths.size(); pidx++) {
    ArrayList path = paths.get(pidx);
    for (int vidx = 0; vidx < path.size()-1; vidx++) {
      PVector v1 = (PVector)path.get(vidx);
      PVector v2 = (PVector)path.get(vidx+1);
      line(v1.x, v1.y, v2.x, v2.y);
    }
  }
}

void mouseMoved() {
  if (mouseButton == RIGHT) {
    paths = new ArrayList();
    currentPathIdx = -1;
    
  }

  
}


void mousePressed() {
  if (mouseButton == RIGHT) {
    paths = new ArrayList();
    currentPathIdx = -1;
  }
  else {
    paths.add(new ArrayList());
    currentPathIdx++;
  }
}

void mouseReleased() {
  int numpoints = getpointcount(paths);
    println("points:" + numpoints);
    pointsX = new float[numpoints];
    pointsY = new float[numpoints];  

  
    int idx = 0;
    for(int pidx = 0; pidx < paths.size(); pidx++) {
      ArrayList path = paths.get(pidx);
      for (int vidx = 0; vidx < path.size()-1; vidx++) {
        PVector p = (PVector)path.get(vidx);

        pointsX[idx] = p.x / width*2;
        pointsY[idx] = p.y / height*2;
        idx++;
      }
    }
    
    OscMessage pointsxMessage = new OscMessage("/pointsx");
    OscMessage pointsyMessage = new OscMessage("/pointsy");
    pointsxMessage.add(pointsX);
    pointsyMessage.add(pointsY);
    oscP5.send(pointsxMessage, network);
    oscP5.send(pointsyMessage, network);
}


/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  /* print the address pattern and the typetag of the received OscMessage */
  print("### received an osc message.");
  print(" addrpattern: "+theOscMessage.addrPattern());
  println(" typetag: "+theOscMessage.typetag());
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
