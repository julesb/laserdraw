public class IldaPoint {
  short x;
  short y;
  short z;
  int[] rgb;
  int colorIdx;
  int blank;
  int last;
  
  public IldaPoint(short x, short y, short z, int colorIdx, int blank, int last) {
    this.x = x;
    this.y = y;
    this.z = z;
    //this.rgb = rgb;
    this.colorIdx = colorIdx;
    this.blank = blank;
    this.last = last;
  }
  
  public String toString() {
    return "[" + x + " " + y + " " + z + "] "
         + "[b: " + this.blank + ", l: " + this.last + " ] "
         + "[c: " + this.colorIdx + "]"; 
  
  }
  


}
