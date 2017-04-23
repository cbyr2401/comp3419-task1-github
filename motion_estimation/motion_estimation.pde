import processing.video.*;

PImage frame;
PImage img;
PImage overlay;
int counter = 1;
//PrintWriter ofile;

void setup(){
  
  // this is used for testing purposes...
  size(270,480);
  // original 1456,2592
  img = loadImage("motiontest3E (Mobile).jpg");
  frame = loadImage("motiontest3F (Mobile).jpg");
  //ofile = createWriter("displacements.txt");
  
}


void draw() {
  if( counter == 1 ) {
    image(frame, 0, 0);
    searchBlocks(img, frame, 5);
    counter = 0;
  }
}




// only requied when there is a movie being played.
// otherwise, ignore.
void movieEvent (Movie m){

}


void searchBlocks(PImage A, PImage B, int gridsize){
  int NEIGHBOURHOOD = 8 * gridsize;
  int LARGENUM = 20000000;
  int NUM_GRIDS = ((A.width*A.height) / (gridsize * gridsize)) + 1;
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
  
  // iterate through all the grids from the first image 1 time.
  for(int ax = 0; ax < WLIMITPX; ax += gridsize){
    if(ax != 0) {di++; }
    dj = 0;
    for(int ay = 0; ay < HLIMITPX; ay += gridsize){
      if(ay != 0) {dj++;}
      float [] dists = new float[(NEIGHBOURHOOD) * (NEIGHBOURHOOD)];
      //fillarray(dists, LARGENUM);
      bl_index = 0;
      
      // iterate through all the grids in the second image NUM_GRIDS times
      //  for each grid block from the first image.
      for(int bx = ax - NEIGHBOURHOOD ; (bx >= 0) && (bx < ax + NEIGHBOURHOOD) && (bx < WLIMITPX); bx += gridsize){
        for(int by = ay - NEIGHBOURHOOD; (by >= 0) && (by < ay + NEIGHBOURHOOD) && (by < HLIMITPX); by += gridsize){
          // complete the SSD for each block and store the result...
          if(bx > -1 && by > -1 && ax > -1 && ay > -1){
            float res = SSD(A, ax, ay, B, bx, by, gridsize);
            dists[bl_index++] = res;
          }
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
      
      // compare all the results and select the smallest value
      int index = findmin(dists);
      
      // index is the index-th block to be processed, with this information
      //  we should be able to get the (x, y) cordinates for the block
      //   in question.
      int xp = ax + round(dists[index]);
      int yp = ay + round(dists[index]);
      
      
      //int xp = (index % WGRIDACROSS) * gridsize;
      //int yp = floor(index / HGRIDACROSS) * gridsize;
      
      println("**found block: (" + xp + "," + yp + ")");
      println("**current block: (" + ax + "," + ay + ")");
      
      
      // insert the vector into the storage array
      
      displacement[di][dj][0] = xp;
      displacement[di][dj][1] = yp;
    
      println("Proccessed Block: " + blockcount++);
    }
  }
  
  /*
  // debug output to file
  for(int i=0; i < WGRIDACROSS; i++){
    for(int j=0; j < HGRIDACROSS; j++){
      ofile.println(displacement[di][dj][0] + ", " + displacement[di][dj][1]); 
    }
  }
  ofile.flush();
  ofile.close();
  
  exit();
  */
  
  
  
  
  
  // TODO:  Process the displacements and display them somehow
  println("Drawing Displacements...");
  
  blockcount = 0;
  
  int ax = 0;
  int ay = 0;
  int bx = 0;
  int by = 0;
  
  PGraphics disfield = createGraphics(A.width, B.height);
  disfield.beginDraw();
  disfield.stroke(0,0,0);
  
  for(int x=0; x < WGRIDACROSS; x++){
    for(int y=0; y < HGRIDACROSS; y++){
      // find the centre of the block from the first image:
      ax = (x*gridsize) + int(gridsize/2);
      ay = (y*gridsize) + int(gridsize/2);
      
      // find the centre of the block from the displacement:
      bx = displacement[x][y][0] + int(gridsize/2);
      by = displacement[x][y][1] + int(gridsize/2);
      
      println("Drawing Line...Block: " + blockcount++);
      println("** A (" + ax + "," + ay + ")");
      println("** B (" + bx + "," + by + ")");
      
      //if ((bx > 0 && by > 0) && (ax > 0 && ay > 0)) {
        // draw displacement
        //disfield.line(bx, by, ax, ay);
        arrowdraw(ax, bx, ay, by);
     // }
      
      
    }
  }
  
  // end the drawing on the graphic
  disfield.endDraw();
  image(disfield, 0, 0);  
  
}

int findmin(float[] list){
 float result = min(list);
 println("**minimum result: " + result);
 int i = 0;
 // search the list to get the index of that min.
 for (i = 0; i < list.length; i++){
   if(list[i] == result) break;
 }
 println("**(block, value): (" + i + ", " + list[i] + ")");
 return i;
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
      sum += sqrt(pow(red(A.pixels[cellA]) - red(B.pixels[cellB]), 2)
            + pow(green(A.pixels[cellA]) - green(B.pixels[cellB]), 2) 
            + pow(blue(A.pixels[cellA]) - blue(B.pixels[cellB]), 2));
    }
  }
  return (float)sum;  
}

void fillarray(float[] arr, float value){
   for(int i=0; i < arr.length; i++){
     arr[i] = value;
   }
   
  
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