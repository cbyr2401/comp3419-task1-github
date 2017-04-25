import processing.video.*;

PImage frame;
PImage img;
Movie m;
int counter = 1;
int M_BLOCKS = 25;

String moviepath = "video1.mp4";
int framenumber = 1; 
int phase = 1; // The phase for precessing pipeline : 1, saving frames of background; 2. overwrite the background frames with 
int bgctr = 0;

char[] alphabet = {'A', 'B', 'C', 'E', 'F', 'G', 'H'};

void setup(){
  
  // this is used for testing purposes...
  size(1536,512);
  // original 1456,2592
  //img = loadImage("motiontest3A (Mobile).jpg");
  //frame = loadImage("motiontest3B (Mobile).jpg");
  //img = loadImage("motiontest2A.png");
  //frame = loadImage("motiontest2B.png");
  m = new Movie(this, sketchPath(moviepath));
  
}


void draw() {
  
  /*
  if( counter < 5 ) {
    
    frame = loadImage("motiontest3" + alphabet[counter] + " (Mobile).jpg");
    
    image(img, 0, 0);
    //image(frame, 1024, 0);
    image(frame, 270, 0);
    
    searchBlocks(img, frame, 9);
    
    counter++;
    
    img = frame;
    
    delay(750);
    
  }
  */
  // Clear the background with black colour
  float time = m.time();
  float duration = m.duration();
  float whereweare = time / duration;

  if( time >= duration ) { 
    if (phase == 1) {
      m = new Movie(this, sketchPath(moviepath));
      m.frameRate(120); // Play your movie faster
      m.play();
      phase = 2;
      bgctr = framenumber;
      framenumber = 1;
    }
    else if (phase == 2){
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
            frame = loadImage(sketchPath("") + "BG/"+nf(framenumber % bgctr, 4) + ".tif");
  
            // Overwrite the background 
            image(m, 0, 0);
            
            // process the difference
            searchBlocks(frame, m, M_BLOCKS);
            
            // display the difference on the frame (lines, etc)
            // done in above function
            
            // save the frame
            saveFrame(sketchPath("") + "/composite/" + nf(framenumber, 4) + ".tif"); 
      }
    }
}


// only requied when there is a movie being played.
// otherwise, ignore.
void movieEvent (Movie m){

}


void searchBlocks(PImage A, PImage B, int gridsize){
  int NEIGHBOURHOOD = 8 * gridsize;
  int LARGENUM = 20000000;
  //int NUM_GRIDS = ((A.width*A.height) / (gridsize * gridsize)) + 1;
  //int NUM_GRIDS_ACROSS = round(A.width / gridsize) + 1;
  int WLIMITPX = A.width - (gridsize-1);
  int HLIMITPX = A.height - (gridsize-1);
  int WGRIDACROSS = round(A.width / gridsize);
  int HGRIDACROSS = round(A.height / gridsize);
  /*
  println("------DEBUG-------");
  println("NUM_GRIDS: " + NUM_GRIDS);
  println("NUM_GRIDS_ACROSS: " + NUM_GRIDS_ACROSS);
  println("------END DEBUG-------");
  delay(1500);
  */
  
  int[][][] displacement = new int[WGRIDACROSS][HGRIDACROSS][2];
  
  int di = 0;
  int dj = 0;
  int bl_index = 0;
  int blockcount = 0;
  int loopcount = 0;
  
  int[] coords = new int[2];
  float resmin = LARGENUM;
  
  // iterate through all the grids from the first image 1 time.
  for(int ax = 0; ax < WLIMITPX; ax += gridsize){
    if(ax != 0) {di++; }
    dj = 0;
    for(int ay = 0; ay < HLIMITPX; ay += gridsize){
      if(ay != 0) {dj++;}
      
      resmin = LARGENUM;
      coords[0] = ax;
      coords[1] = ay;
      
      // iterate through all the grids in the second image NUM_GRIDS times
      //  for each grid block from the first image.
      for(int bx = ax - NEIGHBOURHOOD ; bx < ax + NEIGHBOURHOOD && (bx < WLIMITPX); bx += gridsize){
        for(int by = ay - NEIGHBOURHOOD; by < ay + NEIGHBOURHOOD && (by < HLIMITPX); by += gridsize){
          // complete the SSD for each block and store the result...
          if( bx > -1 && by > -1 && ax > -1 && ay > -1){
            float res = SSD(A, ax, ay, B, bx, by, gridsize);
            //if (res < resmin && res > 0){
            if (res < resmin){
              resmin = res;
              coords[0] = bx;
              coords[1] = by;
            }
            
          }
          
          if(bx >= WLIMITPX || by >= HLIMITPX) break;
          
          /*
          println("A Coordinates: (" + ax + ", " + ay + ")");
          println("B Coordinates: (" + bx + ", " + by + ")");
          println("loop count: | " + loopcount + " |");
          println("SSD: " + dists[bl_index-1]);
          delay(750);
          loopcount += 1;
          */
        }
      }
      
      loopcount = 0;
      
      /*
      for(int i=0; i < NUM_GRIDS; i++){
        println(dists[i]);
      }
      exit();
      */
      
      /*
      println("**found block: (" + coords[0] + "," + coords[1] + ")");
      println("**current block: (" + ax + "," + ay + ")");
      */
      
      // insert the vector into the storage array
      
      displacement[di][dj][0] = coords[0];
      displacement[di][dj][1] = coords[1];
    
      /* println("Proccessed Block: " + blockcount++); */
    }
  }
  
  
  
  // TODO:  Process the displacements and display them somehow
  println("Drawing Displacements...");
  
  blockcount = 0;
  
  int ax = 0;
  int ay = 0;
  int bx = 0;
  int by = 0;
  
  PGraphics disfield = createGraphics(A.width, B.height);
  disfield.beginDraw();
  disfield.stroke(255,255,255);
  
  for(int x=0; x < WGRIDACROSS; x++){
    for(int y=0; y < HGRIDACROSS; y++){
      // find the centre of the block from the first image:
      ax = (x*gridsize) + int(gridsize/2);
      ay = (y*gridsize) + int(gridsize/2);
      
      // find the centre of the block from the displacement:
      bx = displacement[x][y][0] + int(gridsize/2);
      by = displacement[x][y][1] + int(gridsize/2);
      
      /*
      println("Drawing Line...Block: " + blockcount++);
      println("** A (" + ax + "," + ay + ")");
      println("** B (" + bx + "," + by + ")");
      */
      
      if ( ax == bx && ay == by ){
        continue;
      }
      
      //if ((bx > 0 && by > 0) && (ax > 0 && ay > 0)) {
        // draw displacement
        disfield.line(bx, by, ax, ay);
        disfield.ellipse(bx,by,2,2);
        //arrowdraw(ax, bx, ay, by);
     // }
      
      
    }
  }
  
  // end the drawing on the graphic
  disfield.endDraw();
  image(disfield, 0, 0); 
}


// SSD(Block_i, Block_i+1) = squareroot ( 
//
//
//

float SSD(PImage A, int ax, int ay, PImage B, int bx, int by, int blocksize){
  double sum = 0;
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
  
  sum = sqrt((float)sum);
  return (float)sum; 
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