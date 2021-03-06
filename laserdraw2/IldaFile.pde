import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;

import java.util.Arrays;


public class IldaFile {
  String filename;
  byte[] bytes;
  ArrayList<IldaFrame> frames = new ArrayList();

  public IldaFile(String filename) {
    this.filename = filename;
    this.bytes = loadFile();
    int frameOffset = 0;
    IldaFrame frame;
    do {
      frame = new IldaFrame(frameOffset, this.bytes);
      frames.add(frame);
      frameOffset += frame.byteCount;
    } while (frame.header.numRecords > 0 && frameOffset < this.bytes.length);
  }


  byte[] loadFile() {
    byte[] bytes = {};
    try{
      bytes = Files.readAllBytes(Paths.get(this.filename));
      println("loaded file " + this.filename + ": bytes:" + bytes.length);
    } catch(IOException e) {
      e.printStackTrace();
    }  
    return bytes;
  }

}


public class IldaFrame {
  public IldaHeader header;
  public ArrayList<IldaPoint> points = new ArrayList();
  public int byteCount;

  public IldaFrame(int frameOffset, byte[] bytes) {
    parse(frameOffset, bytes);
  
  }

  void parse(int frameOffset, byte[] bytes) {
    // TODO: Dont copy the bytes. Calculate offsets into main array instead. 
    byte[] headerBytes = Arrays.copyOfRange(bytes, frameOffset, frameOffset+32);
    this.header = new IldaHeader(headerBytes);
    
    int recsize = this.header.getFormatRecordSize();
    int reccount = this.header.numRecords;
    int datalen = recsize * reccount;
    this.byteCount = reccount == 0? 32: 32 + datalen;
    int dataStartIdx = frameOffset + 32;
    
    
    for (int i=dataStartIdx; i < dataStartIdx+datalen; i += recsize) {
      byte[] recBytes = Arrays.copyOfRange(bytes, i, i+recsize);

      switch(this.header.formatCode) {
         case IldaHeader.ILDA_3D_INDEXED:
           short x = IldaUtil.bytesToShort(Arrays.copyOfRange(recBytes, 0, 2));
           short y = IldaUtil.bytesToShort(Arrays.copyOfRange(recBytes, 2, 4));
           short z = IldaUtil.bytesToShort(Arrays.copyOfRange(recBytes, 4, 6));
           int status = recBytes[6];
           int colIdx = recBytes[7];
           int st_last   = (status & (1 << 7)) >> 7;
           int st_blank  = (status & (1 << 6)) >> 6;
           int[] rgb = IldaUtil.DEFAULT_PALETTE[colIdx];
           IldaPoint p = new IldaPoint(x, y, z, colIdx, st_blank, st_last);
           this.points.add(p);
           //println(p.toString());
           break;
           
         case IldaHeader.ILDA_2D_INDEXED:
           print("NOT IMPLEMENTED: ILDA_2D_INDEXED");
           break;
         
         case IldaHeader.ILDA_COLOR_PALETTE:
           print("NOT IMPLEMENTED: ILDA_COLOR_PALETTE");
           break;
         
         case IldaHeader.ILDA_3D_RGB:
           print("NOT IMPLEMENTED: ILDA_3D_RGB");
           break;
         
         case IldaHeader.ILDA_2D_RGB:
           print("NOT IMPLEMENTED: ILDA_2D_RGB");
           break;
      }
    }
    println("Read points: " + this.points.size());
  }
}


public class IldaHeader {
  String identifier;
  int formatCode;
  String name;
  String companyName;
  int numRecords;
  int frameNumber;
  int totalFrames;
  int projectorNumber;
  int headerStartOffset = -1;
  
  static final int ILDA_3D_INDEXED    = 0;
  static final int ILDA_2D_INDEXED    = 1;
  static final int ILDA_COLOR_PALETTE = 2;
  static final int ILDA_3D_RGB        = 4;
  static final int ILDA_2D_RGB        = 5;
  
  public IldaHeader(byte[] headerBytes) {
    String id = new String(Arrays.copyOfRange(headerBytes, 0, 4));
    if (! id.equals("ILDA")) {
      println("ERROR: Invalid file identifier: '" + id + "'");
    }
    else {
      this.identifier = id;
    }
    
    this.formatCode = headerBytes[7];
    this.name = new String(Arrays.copyOfRange(headerBytes, 8, 16));
    this.companyName = new String(Arrays.copyOfRange(headerBytes, 16, 24));
    this.numRecords  = IldaUtil.bytesToShort(Arrays.copyOfRange(headerBytes, 24, 26));
    this.frameNumber = IldaUtil.bytesToShort(Arrays.copyOfRange(headerBytes, 26, 28));
    this.totalFrames = IldaUtil.bytesToShort(Arrays.copyOfRange(headerBytes, 28, 30));

    print("HEADER:\n" + this.toString());
    
  }
  
  public IldaHeader() {
  }
  
  public String getFormatString() {
    switch(this.formatCode) {
      case ILDA_3D_INDEXED:    return "ILDA_3D_INDEXED";
      case ILDA_2D_INDEXED:    return "ILDA_2D_INDEXED";
      case ILDA_COLOR_PALETTE: return "ILDA_COLOR_PALETTE";
      case ILDA_3D_RGB:        return "ILDA_3D_RGB";
      case ILDA_2D_RGB:        return "ILDA_2D_RGB";
      default:
        return "UNDEFINED FORMAT: " + this.formatCode;
    }
  }
  
  public int getFormatRecordSize() {
    switch(this.formatCode) {
      case ILDA_3D_INDEXED:    return 8;
      case ILDA_2D_INDEXED:    return 6;
      case ILDA_COLOR_PALETTE: return 3;
      case ILDA_3D_RGB:        return 10;
      case ILDA_2D_RGB:        return 8;
      default:
        return -1;
      
      
    }
  }
  
  
  public String toString() {
    return "  ID:            " + this.identifier + "\n"
         + "  Format:        " + this.getFormatString() + "\n"
         + "  Name:          " + this.name + "\n"
         + "  Company Name:  " + this.companyName + "\n"
         + "  Num Records:   " + this.numRecords + "\n"
         + "  Frame Number:  " + this.frameNumber + "\n"
         + "  Total Frames:  " + this.totalFrames + "\n"
         ;
  
  }
  

}

static class IldaUtil {
  
  public static short bytesToShort(byte[] bytes) {
    return ByteBuffer.wrap(bytes).order(ByteOrder.BIG_ENDIAN).getShort();
  }
  
  public static byte[] shortToBytes(short value) {
    return ByteBuffer.allocate(2).order(ByteOrder.BIG_ENDIAN).putShort(value).array();
  }
  
  public static String RGBToHexString(int[] rgb) {
    return String.format("#%02x%02x%02x", rgb[0], rgb[1], rgb[2]);
  }
  
  public static final int[][] DEFAULT_PALETTE = {
    {255, 0, 0},
    {255, 16, 0},
    {255, 32, 0},
    {255, 48, 0},
    {255, 64, 0},
    {255, 80, 0},
    {255, 96, 0},
    {255, 112, 0},
    {255, 128, 0},
    {255, 144, 0},
    {255, 160, 0},
    {255, 176, 0},
    {255, 192, 0},
    {255, 208, 0},
    {255, 224, 0},
    {255, 240, 0},
    {255, 255, 0},
    {224, 255, 0},
    {192, 255, 0},
    {160, 255, 0},
    {128, 255, 0},
    {96, 255, 0},
    {64, 255, 0},
    {32, 255, 0},
    {0, 255, 0},
    {0, 255, 36},
    {0, 255, 73},
    {0, 255, 109},
    {0, 255, 146},
    {0, 255, 182},
    {0, 255, 219},
    {0, 255, 255},
    {0, 227, 255},
    {0, 198, 255},
    {0, 170, 255},
    {0, 142, 255},
    {0, 113, 255},
    {0, 85, 255},
    {0, 56, 255},
    {0, 28, 255},
    {0, 0, 255},
    {32, 0, 255},
    {64, 0, 255},
    {96, 0, 255},
    {128, 0, 255},
    {160, 0, 255},
    {192, 0, 255},
    {224, 0, 255},
    {255, 0, 255},
    {255, 32, 255},
    {255, 64, 255},
    {255, 96, 255},
    {255, 128, 255},
    {255, 160, 255},
    {255, 192, 255},
    {255, 224, 255},
    {255, 255, 255},
    {255, 224, 224},
    {255, 192, 192},
    {255, 160, 160},
    {255, 128, 128},
    {255, 96, 96},
    {255, 64, 64},
    {255, 32, 32}
  };
}
