import processing.video.*;

PImage frame;
PImage img;
PImage overlay;

Movie m;
int counter = 1;
int M_BLOCKS = 13;

String moviepath = "video3.mp4";
int framenumber = 1; 
int phase = 1; // The phase for precessing pipeline : 1, saving frames of background; 2. overwrite the background frames with 
int bgctr = 0;

PGraphics disfield;

char[] alphabet = {'A', 'B', 'C', 'E', 'F', 'G', 'H'};

void setup(){
  size(1296,972);
  frameRate(120); // Make your draw function run faster
  
  m = new Movie(this, sketchPath(moviepath));
  m.frameRate(120); // Play your movie faster
  
  framenumber = 0; 
  fill(255, 255, 255); // Make the drawing colour white
  
  //play the movie one time, no looping 
  m.play();  
}


void draw() {
  
  // Clear the background with black colour
  float time = m.time();
  float duration = m.duration();
  
  
  if( time >= duration ) { 
    if (phase == 1) {
      
      phase = 2;
      bgctr = framenumber;
      PImage temp;
      framenumber = 1;
      
      temp = loadImage(sketchPath("") + "BG/"+nf(framenumber % bgctr, 4) + ".tif");
      
      for( framenumber = 2; framenumber < bgctr; framenumber++ ){
        print("Processing Frame: ", framenumber-1);
        // open the frame
        frame = loadImage(sketchPath("") + "BG/"+nf(framenumber % bgctr, 4) + ".tif");

        // Overwrite the background 
        clear();
        background(0);
        
        // process the difference and display the difference on the frame (lines, etc)
        searchBlocks(temp, frame, M_BLOCKS);
        
        // save the displacement field
        saveFrame(sketchPath("") + "/displacement/" + nf(framenumber-1, 4) + ".tif"); 
        
        // Overwrite the background 
        image(frame, 0, 0);
        image(disfield, 0, 0);
        
        // save the frame
        saveFrame(sketchPath("") + "/composite/" + nf(framenumber-1, 4) + ".tif"); 
        
        temp = frame;
        
        println(" ... [success]");
      }
      
      framenumber = 1;
      m = new Movie(this, sketchPath(moviepath));
      m.frameRate(120); // Play your movie faster
      m.play();
    }
    else if (phase == 2){
      println("Program execution finished! (level 1)");
      exit(); // End the program when the second movie finishes
    }
  }
  

  if (m.available()){
    background(0, 0, 0);
    m.read(); 
      
      if (phase == 1){
        image(m, 0, 0);
        m.save(sketchPath("") + "BG/"+nf(framenumber, 4) + ".tif"); // They say tiff is faster to save, but larger in disks 
      }
      else if (phase == 2) {
        if(framenumber < bgctr - 1){
         // play back all the frames at the desired framerate:
         frame = loadImage(sketchPath("") + "/composite/"+nf(framenumber % bgctr, 4) + ".tif");
         image(frame, 0, 0);
        }else{
           println("Program execution finished! (level 2)");
           exit(); 
        }
    }
    
    framenumber++; 
  }
}


// only requied when there is a movie being played.
// otherwise, ignore.
void movieEvent (Movie m){

}


void searchBlocks(PImage A, PImage B, int gridsize){
  int NEIGHBOURHOOD = 3 * gridsize;
  int LARGENUM = 20000000;
  int WLIMITPX = A.width - (gridsize-1);
  int HLIMITPX = A.height - (gridsize-1);
  int WGRIDACROSS = round(A.width / gridsize);
  int HGRIDACROSS = round(A.height / gridsize);
  int HALFGRID = int(gridsize/2);
  
  // 3D Matrix for holding the displacements of each image
  int[][][] displacement = new int[WGRIDACROSS][HGRIDACROSS][2];
  
  // index variables for each image
  int di = 0;
  int dj = 0;
  
  // temporary storage for the 
  int[] coords = new int[2];
  float resmin = LARGENUM;
  float res = 0;
  
  // variables for drawing on the lines
  disfield = createGraphics(A.width, A.height);
  disfield.beginDraw();
  disfield.stroke(255,255,255);
  
  // iterate through all the grids from the first image 1 time.
  for(int ax = 0; ax < WLIMITPX; ax += gridsize){
    // reset the row counter.
    dj = 0;
    for(int ay = 0; ay < HLIMITPX; ay += gridsize){
      // set the starting values so that if the same block comes up, 
      // it will be ok.
      resmin = LARGENUM;
      coords[0] = ax;
      coords[1] = ay;
      
      // iterate through all the grids in the second image NUM_GRIDS times
      //  for each grid block from the first image.
      for(int bx = ax - NEIGHBOURHOOD ; bx < ax + NEIGHBOURHOOD && (bx < WLIMITPX); bx += gridsize){
        for(int by = ay - NEIGHBOURHOOD; by < ay + NEIGHBOURHOOD && (by < HLIMITPX); by += gridsize){
          // complete the SSD for each block and store the result...
          if( bx > -1 && by > -1 && ax > -1 && ay > -1){
            res = SSD(A, ax, ay, B, bx, by, gridsize);
            if (res < resmin){
              resmin = res;
              coords[0] = bx;
              coords[1] = by;
            } 
          }
          
          if(bx >= WLIMITPX || by >= HLIMITPX) break;
        }
      }
      
      if ( resmin > 5000 ) {
        // insert the vector into the storage array
        displacement[di][dj][0] = coords[0];
        displacement[di][dj][1] = coords[1];
      } else {
        continue;
      }
      
      
      // draw the vector onto the displacement field
      // if any of the blocks are the same, don't draw anything
      if ( ax == coords[0] && ay == coords[1] ){
        continue;
      }
      
      // draw displacement
      disfield.line(coords[0]+HALFGRID, coords[1]+HALFGRID, ax+HALFGRID, ay+HALFGRID);
      disfield.ellipse(coords[0]+HALFGRID,coords[1]+HALFGRID,3,3);
      disfield.ellipse(ax+HALFGRID,ay+HALFGRID,3,3);
      
      // increment the y-coordinate counter for the displacement array
      dj++;
    }
    
    // increment the x-coordinate counter for the displacement array
    di++;
  }

  // end the drawing on the graphic
  disfield.endDraw();
  image(disfield, 0, 0); 
  
  // release all memory
  
}


// SSD(Block_i, Block_i+1) = squareroot ( 
//  The minimum sum difference of each pixel
float SSD(PImage A, int ax, int ay, PImage B, int bx, int by, int blocksize){
  float sum = 0;
  int cellA = 0;
  int cellB = 0;
  
  for (int x = 0; x < blocksize; x++){
    for(int y = 0; y < blocksize; y++){
      cellA = (ax + x) + ((ay + y) * A.width);
      cellB = (bx + x) + ((by + y) * B.width);
      sum += pow(red(A.pixels[cellA]) - red(B.pixels[cellB]), 2)
            + pow(green(A.pixels[cellA]) - green(B.pixels[cellB]), 2) 
            + pow(blue(A.pixels[cellA]) - blue(B.pixels[cellB]), 2);
    }
  }
  
  //sum = sqrt((float)sum);
  return sum; 
}



void arrowdraw(int x1, int y1, int x2, int y2) { 
  line(x1, y1, x2, y2);
  pushMatrix(); 
  translate(x2, y2); 
  float a = atan2(x1-x2, y2-y1); 
  rotate(a); 
  line(0, 0, -10, -10);
  line(0, 0, 10, -10); 
  popMatrix(); 
}