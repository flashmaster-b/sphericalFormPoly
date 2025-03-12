import processing.svg.*;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Formatter;
import java.util.Arrays;
import java.util.Map;
import com.jogamp.opengl.GLProfile;
{
  GLProfile.initSingleton();
}


/**
 * Creates a form and membrane of a spherical body, with modulations and deviations
 * based on continuous noise and/or sensor values.
 *
 * @version  4.2.2 7 Nov 2022
 * @author   Juergen Buchinger
 */

/** variable for continuous rotation of matrix in draw loop */
private float rt=INITIAL_X_ROTATION;

/** absolute column width */
int COLUMN_WIDTH;

/** speed of rotation of matrix */
private float rotationSpeed = 0.1;

/** if true, program will record every frame it draws and save it to sketch folder */
private boolean rec = false;

/** will be set true once the program starts with either a new dna or an existing one */
boolean go = false;

/** set true if you want to rotate the form around the x-Axis */
boolean rotate = false;

/** this is set to false to not draw membrane for one frame when switching Membranes */
boolean drawMembrane = true;

/** set this true if you want to shape the modulations with mouse movements rather than data */
boolean manual = false;
boolean rumpManual = true;

/** if doing a mutation, this will be set to false, it will be set true when the mutation is finished */
boolean mutating = false;

/** seed for the pseudo random number generator, this is neccessary to save dna */
private int randomSeed;

/** seed for the noise field generator, this is neccessary to save dna */
private int noiseSeed;

/** the cell membranes to be created */
private Membrane[] m = new Membrane[SENSOR_IDS.length];

/** zoom value for display (setting the whole thing back in 3D space a bit */
float zoom = -100;

/** Sensor class for environmental values */
Sensor3[] sensor = new Sensor3[SENSOR_IDS.length];

/** set this to paint mesh instead of pointcloud */
boolean tri = true;

/** counter for grid redraw effect */
int gridCounter = 0;

/** counter for column redraw effect */
int colCounter = 0;

/** counter for pointcloud redraw effect */
int ringCounter = 0;

/** a PShape of the text "mutation threshold" for the graph */
PShape graphLabel;

/** the position in the graph to paint towards */
public int graphPos=0;

/** max and min values for every sensor */
FloatDict max;
FloatDict min;
boolean fdset = false;

/** labels for the frame */
String[] LABELS = {"EPIZOON SPECIMEN SIMULATION",getDate()+"            "+SENSOR_COORDINATES[0],"v4.2.2","","#!/bin/processing-java","HSLU   D&K   CCVN   AGBB   MiED"};

/** labels for the values displayed in column. FIXME: This should probably 
 * be derived from the VALUES denominator when integrating Sensor2 class
 */
String[] labels = {
    "#SPECIMEN",
    "#PHENOTYPE",
    "cap smooth / width",
    "rump smooth / width",
    "cap size",
    "elongation",
    "predicted lifespan",
    "#ENVIRONMENT",
    "sensor id",
    "relative humidity",
    "temperature",
    "atmospheric pressure",
    "volatile organic compounds",
    "particulate matter (< 2.5 µm)",
    "particulate matter (< 10 µm)",
    "#SIMULATION",
    "frame rate",
    "current iter.",
    "base hue"
  };
  
  
/** labels for the values displayed in column. FIXME: This should probably 
 * be derived from the VALUES denominator when integrating Sensor2 class
 */
String[] labels2 = {
    "#EVOLUTION",
    "current generation",
    "spontaneous mutation",
    "last mutation",
    "trigger",
    "next regular mutation in",
    "#SPONTANEOUS MUTATION TRIGGERS"
  };

/** console for graphic interface */
Console console; 

/** image of map to show sensor location */
PImage map;
  
/** Graph of standard deviation */
PShape[] graph;


/** number of the sensor location FIXME: should be replaced by value from Sensor2 */
int s_loc = 0;

/** timer for recurring events */
Timer t = new Timer();

  
void setup() {
  size(3840,2160, P3D);
  // fullScreen(P3D);
  smooth(8);
  println(width + " x " + height);
  colorMode(HSB,360,100,100);
  stroke(0,0,100);
  fill(213);
  noClip();
  PFont mono = createFont("font/OCRA.otf", 18);
  textFont(mono);
  map = loadImage("data/sensor-map.png");
  COLUMN_WIDTH = int(width*COLUMN_WIDTH_);
  randomSeed = int(random(-2147483648,2147483647)); 
  noiseSeed = int(random(-2147483648,2147483647));  
  randomSeed(randomSeed);
  noiseSeed(noiseSeed);
  console = new Console();
  println("Starting...");
  
  if(INDEX_REWRITE) {
    JSONObject index = new JSONObject();
    index.setInt("randomSeed", randomSeed);
    index.setInt("noiseSeed", noiseSeed);
    JSONArray specimens = new JSONArray();
    index.setJSONArray("specimens", specimens);
    saveJSONObject(index, "history/index.json");
    for(int i=0; i<sensor.length; i++) {
      println("Setting up sensor"+i);
      print("Loading historical data... ");
      sensor[i] = new Sensor3("https://ext.differentspace.com/json_tts.php",SENSOR_IDS[i], i);
      println("done.");
      SENSOR_LOCATIONS[i].x = SENSOR_LOCATIONS[i].x/map.width*COLUMN_WIDTH;
      SENSOR_LOCATIONS[i].y = SENSOR_LOCATIONS[i].y/map.width*COLUMN_WIDTH;
      print("Creating membrane... ");
      m[i] = new Membrane(i);
      m[i].baseHue = BASE_HUE[i];
      m[i].pheno = m[i].geno;
      m[i].saveGeno();
      m[i].pheno();
      m[i].lastMutation = sensor[i].pos;
      println("sensor "+i+" pos main: "+sensor[i].pos);
      println("last mutation main: "+m[i].lastMutation);
      sensor[i].clearVariHist();
      println("done ("+m[i].name+").");
    }
  } else {
    JSONObject index = loadJSONObject("history/index.json");
    JSONArray specimens = index.getJSONArray("specimens");
    for(int i=0; i<specimens.size(); i++) {
      println("Setting up sensor"+i);
      print("Loading historical data... ");
      sensor[i] = new Sensor3("https://ext.differentspace.com/json_tts.php",SENSOR_IDS[i], i);
      println("done.");
      SENSOR_LOCATIONS[i].x = SENSOR_LOCATIONS[i].x/map.width*COLUMN_WIDTH;
      SENSOR_LOCATIONS[i].y = SENSOR_LOCATIONS[i].y/map.width*COLUMN_WIDTH;
      JSONObject s = specimens.getJSONObject(i);
      JSONObject geno = loadJSONObject("history/"+s.getString("name")+"/"+s.getInt("gen")+".json");
      JSONObject min = geno.getJSONObject("min");
      JSONObject max = geno.getJSONObject("max");
      sensor[i].setMinMax(min,max);
      print("Loading membrane... ");
      m[i] = new Membrane(i, geno);
      println("done ("+s.getString("name")+").");
      sensor[i].clearVariHist();
    }
  }
  
  map.resize(COLUMN_WIDTH,0);
  textAlign(LEFT,TOP);
  graph = new PShape[MUTATION_MEASURES.length];
  LABELS[4] = "#("+randomSeed+"/"+noiseSeed+")";
  
  console.read("Setting up perimeters... done.");
  console.read("seed for pseudo random number generator: "+randomSeed);
  console.read("seed for perlin noise space: "+noiseSeed);
  console.read("Starting simlulation...");
}

void keyPressed() {  
  if(key=='r') {
    rotate = !rotate;
  } else if(key=='s') {         // save DNA
    m[s_loc].saveGeno();
  } else if(key=='p') {
    save("img/" + m[s_loc].name + "_" + frameCount + ".jpg");  // save image
  } else if(key=='t') {
    tri = (tri) ? false : true;
  } else if(key=='i') {
    zoom+=50;
  } else if(key=='o') {
    zoom-=50;
  } else if(key=='l') {
    redraw();
  } else if(key == 'n') {
    noLoop();
  } else if(key == 'y') {
    loop();
  } else if(key == 'q') {
    rec = !rec;
  } else if(key == 'm') {
    startMutation(s_loc, "manual");
  } else if(key == 'd') {
    m[s_loc].saveWaveformPart(true);
    m[s_loc].saveWaveformPart(false);
  } else if(key == '.') {
    rumpManual = (rumpManual) ? false : true;
  } else if(key == ',') {
    manual = (manual) ? false : true;
  }
}

void draw() {
  lights();
  background(25);    

  // We will update each sensor in the same interval that the sensor updates
  if(t.delayPassed("sensor", SENSOR_UPDATES * 1000)) {
    for(int i=0; i<sensor.length; i++) {
      sensor[i].next();
      // m[i].memorize(map(sensor[i].getValue("pm25"),sensor[i].getMin("pm25"),sensor[i].getMax("pm25"),0,1));
      // println(sensor[i].sid+": "+sensor[i].getMax("pm25")+" > pm25 < "+sensor[i].getMin("pm25")+" -- "+sensor[i].getValue("pm25"));
    }
  }
  
  // change the active membrane every ROTATION_TIME
  if(t.delayPassed("membrane", ROTATION_TIME * 1000) && !mutating && !manual) {
    s_loc = s_loc+1 >= SENSOR_IDS.length ? 0 : s_loc+1;
       
    m[s_loc].capModSmoothTarget = map(sensor[s_loc].getValue("temp"),sensor[s_loc].getMin("temp"),sensor[s_loc].getMax("temp"),RUMP_MOD_SMOOTH_MAX,RUMP_MOD_SMOOTH_MIN);
    m[s_loc].rumpModSmoothTarget = map(sensor[s_loc].getValue("hg"),sensor[s_loc].getMin("hg"),sensor[s_loc].getMax("hg"),CAP_MOD_SMOOTH_MIN,CAP_MOD_SMOOTH_MAX);
    
    m[s_loc].rumpModWidthTarget = map(sensor[s_loc].getValue("pm10"),sensor[s_loc].getMin("pm10"),sensor[s_loc].getMax("pm10"),RUMP_MOD_WIDTH_MIN,RUMP_MOD_WIDTH_MAX);
    m[s_loc].rumpModWidthTarget = m[s_loc].rumpModWidthTarget < RUMP_MOD_WIDTH_MIN ? RUMP_MOD_WIDTH_MIN : m[s_loc].rumpModWidthTarget;
    m[s_loc].rumpModWidthTarget = m[s_loc].rumpModWidthTarget > RUMP_MOD_WIDTH_MAX ? RUMP_MOD_WIDTH_MAX : m[s_loc].rumpModWidthTarget;
    m[s_loc].rumpModWidthMutationTarget += m[s_loc].rumpModWidthTarget;
    m[s_loc].rumpModWidthDiv++;
    
    m[s_loc].capModWidthTarget = map(sensor[s_loc].getValue("pm25"),sensor[s_loc].getMin("pm25"),sensor[s_loc].getMax("pm25"),CAP_MOD_WIDTH_MIN,CAP_MOD_WIDTH_MAX);
    m[s_loc].capModWidthTarget = m[s_loc].capModWidthTarget < CAP_MOD_WIDTH_MIN ? CAP_MOD_WIDTH_MIN : m[s_loc].capModWidthTarget;
    m[s_loc].capModWidthTarget = m[s_loc].capModWidthTarget > CAP_MOD_WIDTH_MAX ? CAP_MOD_WIDTH_MAX : m[s_loc].capModWidthTarget;
    m[s_loc].capModWidthMutationTarget += m[s_loc].capModWidthTarget;
    m[s_loc].capModWidthDiv++;
    
    float elongInc = map(sensor[s_loc].getValue("bvoc"),sensor[s_loc].getMin("bvoc"),sensor[s_loc].getMax("bvoc"),ELONGATION_MIN,ELONGATION_MAX);
    // m[s_loc].capSizeTarget = map(sensor[s_loc].getValue("eco2"),sensor[s_loc].getMin("eco2"),sensor[s_loc].getMax("eco2"),CAP_SIZE_MIN,CAP_SIZE_MAX);
    if(elongInc > ELONGATION_MAX) m[s_loc].elongationTarget = ELONGATION_MAX;
    m[s_loc].elongationTarget += elongInc;
    m[s_loc].elongationDiv++;
    
    m[s_loc].mutationCycle = int(map(sensor[s_loc].getVari("pm25"),VARI_MIN,VARI_MAX,MUTATION_CYCLE_MAX,MUTATION_CYCLE_MIN));
    if(m[s_loc].mutationCycle < MUTATION_CYCLE_MIN) m[s_loc].mutationCycle = MUTATION_CYCLE_MIN;
    m[s_loc].mutationCycleTarget += m[s_loc].mutationCycle;
    m[s_loc].mutationDiv++;
    
    println("ElongationTarget for "+m[s_loc].name+": "+(m[s_loc].elongationTarget / m[s_loc].elongationDiv));
    m[s_loc].incCapWidth = abs(m[s_loc].capModWidth - m[s_loc].capModWidthTarget) / (frameRate * ROTATION_TIME);
    m[s_loc].incCapSmooth = abs(m[s_loc].capModSmooth - m[s_loc].capModSmoothTarget) / (frameRate * ROTATION_TIME);
    m[s_loc].incRumpWidth = abs(m[s_loc].rumpModWidth - m[s_loc].rumpModWidthTarget) / (frameRate * ROTATION_TIME);
    m[s_loc].incRumpSmooth = abs(m[s_loc].rumpModSmooth - m[s_loc].rumpModSmoothTarget) / (frameRate * ROTATION_TIME);
    m[s_loc].incElongation = abs(m[s_loc].elongation - m[s_loc].elongationTarget) / (frameRate * ROTATION_TIME);
    
    // set counters to zero for slowly constructing interface
    gridCounter = 0;
    colCounter = 0;
    LABELS[1] = sensor[s_loc].date + "            "+SENSOR_COORDINATES[s_loc]; //<>//
  }
  
  if(manual) {
    if(rumpManual) {
      m[s_loc].rumpModSmooth = map(mouseX,0,width,RUMP_MOD_SMOOTH_MIN,RUMP_MOD_SMOOTH_MAX);
      m[s_loc].rumpModWidth = map(mouseY,0,height,RUMP_MOD_WIDTH_MIN,RUMP_MOD_WIDTH_MAX);
      m[s_loc].rumpModSmoothTarget = map(mouseX,0,width,RUMP_MOD_SMOOTH_MIN,RUMP_MOD_SMOOTH_MAX);
      m[s_loc].rumpModWidthTarget = map(mouseY,0,height,RUMP_MOD_WIDTH_MIN,RUMP_MOD_WIDTH_MAX);
    } else {
      m[s_loc].capModSmooth = map(mouseX,0,width,CAP_MOD_SMOOTH_MIN,CAP_MOD_SMOOTH_MAX);
      m[s_loc].capModWidth = map(mouseY,0,height,CAP_MOD_WIDTH_MIN,CAP_MOD_WIDTH_MAX);
      m[s_loc].capModSmoothTarget = map(mouseX,0,width,CAP_MOD_SMOOTH_MIN,CAP_MOD_SMOOTH_MAX);
      m[s_loc].capModWidthTarget = map(mouseY,0,height,CAP_MOD_WIDTH_MIN,CAP_MOD_WIDTH_MAX);
    }
  }
    
  // mutate
  if(mutating) {
    if(m[s_loc].mutate()) {
      rotationSpeed = 2*PI/(frameRate*5);
      rt+=rotationSpeed;
      if(rt > INITIAL_X_ROTATION+2*PI) {
        m[s_loc].gen++;
        console.read("Mutation completed. Generation: "+m[s_loc].gen);
        m[s_loc].pheno();
        m[s_loc].saveGeno();
        mutating = false;
        tri = true;
        rt = INITIAL_X_ROTATION;
        sensor[s_loc].clearVariHist();
        m[s_loc].mutationCycle = m[s_loc].mutationCycleTarget/m[s_loc].mutationDiv;
        m[s_loc].mutationCycleTarget = m[s_loc].mutationCycle;
        m[s_loc].mutationDiv = 1;
        m[s_loc].nextMutation = millis() + m[s_loc].mutationCycle*1000;
      }
    }
  } else {
    m[s_loc].shiftY();
    m[s_loc].pheno();
  }
  drawCSKey();
  fill(213);
  pushMatrix();
  translate(width/2,height/2-console.h/2,zoom);
  rotateX(-.3);
  rotateY(rt);
  if(rotate) {
    rt+=rotationSpeed;
  }
  if(drawMembrane) {
    if(tri) {
      m[s_loc].convertToTriangles();
      shape(m[s_loc].mesh);
    } else {
      shape(m[s_loc].geno);
    }
  } 
  
  shape(m[s_loc].drawCoordinateSystem());
  popMatrix();
  labels[0] = "#SPECIMEN: "+m[s_loc].name;
  drawPointGrid(FRAME_WIDTH, 50, COLUMN_WIDTH);
  margins(FRAME_WIDTH, LABELS); 
  column(COLUMN_WIDTH, FRAME_WIDTH, labels, getValues(0), true);
  column(COLUMN_WIDTH, FRAME_WIDTH, labels2, getValues(1), false);
  console.write(FRAME_WIDTH);
  if(!mutating) {
    for(int i=0; i<MUTATION_MEASURES.length; i++) {
      graph[i] = sensor[s_loc].drawVari(MUTATION_MEASURES[i], COLUMN_WIDTH, GRAPH_HEIGHT);
    }
    graphPos++;
  }
  for(int i=0; i<graph.length; i++) {
    textAlign(LEFT,BOTTOM);
    if(gridCounter > 8 && gridCounter>(i*5+8)) {
      text(MUTATION_LABELS[i], width-FRAME_WIDTH-COLUMN_WIDTH+5, height-FRAME_WIDTH-map.height-(GRAPH_HEIGHT+15)*(i+1)+15+5);
      shape(graph[i], width-FRAME_WIDTH-COLUMN_WIDTH, height-FRAME_WIDTH-map.height-(GRAPH_HEIGHT+15)*(i+1)+15);
    }
  }
  text("STANDARD DEVIATION (s=100)", width-FRAME_WIDTH-COLUMN_WIDTH+5, height-FRAME_WIDTH-map.height-(GRAPH_HEIGHT+15)*graph.length-10);
  stroke(213);
  line(width-FRAME_WIDTH-COLUMN_WIDTH, height-FRAME_WIDTH-map.height-(GRAPH_HEIGHT+15)*graph.length, width-FRAME_WIDTH, height-FRAME_WIDTH-map.height-(GRAPH_HEIGHT+15)*graph.length);
  drawMap(s_loc);
  if(m[s_loc].nextMutation <= millis() && !mutating) {
    startMutation(s_loc, "internal");
  }
  if(rec) {
    saveFrame("mov/membrane-#####.png");
  }
}


void startMutation(int id, String measure) {
  tri = false;
  ringCounter = 1;
  mutating = true;
  s_loc = id;
  m[s_loc].elongationTarget /= m[s_loc].elongationDiv;
  m[s_loc].elongationDiv = 1;
  m[s_loc].capModWidthMutationTarget /= m[s_loc].capModWidthDiv;
  m[s_loc].capModWidthDiv = 1;
  m[s_loc].rumpModWidthMutationTarget /= m[s_loc].rumpModWidthDiv;
  m[s_loc].rumpModWidthDiv = 1;
  m[s_loc].rumpModWidth = m[s_loc].rumpModWidthMutationTarget;
  m[s_loc].capModWidth = m[s_loc].capModWidthMutationTarget;
  m[s_loc].pheno();
  m[s_loc].sphere = m[s_loc].geno;
  m[s_loc].mutationTime = sensor[s_loc].pos - m[s_loc].lastMutation;
  m[s_loc].lastMutation = sensor[s_loc].pos;
  m[s_loc].lastMutator = measure;
  m[s_loc].spontaneousMutation = false;
  console.read("####### Mutation of " + m[s_loc].name + " at " + sensor[s_loc].pos + " triggered by " + measure + " ####");
  console.read("####### Lifespan was " + m[s_loc].mutationTime + " increments");
}

void saveDNA() {
  JSONObject dna = new JSONObject();
  dna.setInt("randomSeed", randomSeed);
  dna.setInt("noiseSeed", noiseSeed);
  dna.setString("name", m[s_loc].name);
  saveJSONObject(dna, "data/"+m[s_loc].name+".json");

  dna.setInt("randomSeed", randomSeed);
  dna.setInt("noiseSeed", noiseSeed);
  dna.setString("name", m[s_loc].name);
  dna.setInt("gen", m[s_loc].gen);
  JSONObject tmin = new JSONObject();
  JSONObject tmax = new JSONObject();
  for(String k : sensor[s_loc].val.keyArray()) {
    tmin.setFloat(k, min.get(k));
    tmax.setFloat(k, max.get(k));
  }
  dna.setJSONObject("min", tmin);
  dna.setJSONObject("max", tmax);
}


/** 
 * draws a key for the coordinate system 
 */
void drawCSKey() {
  pushMatrix();
  translate((width-COLUMN_WIDTH)/2,height);
  textAlign(CENTER);
  fill(210,100,100);
  text("X",0,-5);
  fill(105,100,100);
  text("Y",20,-5);
  fill(0,100,100);
  text("Z",40,-5);
  fill(223);
  text("–",10,-5);
  text("–",30,-5);
  popMatrix();
}
  

/** 
 * draws a frame and grid of points to the screen 
 * @param frame the space of the frame to the end of the screen
 * @param grid the spacing of points of the grid
 * @param column the width of the column
 */
void drawPointGrid(int frame, int grid, int column) {
  noStroke();
  fill(25);
  rect(0,0,frame,height);
  rect(0,0,width,frame);
  rect(width-frame,0,frame,height);
  rect(0,height-frame,width,height);
  fill(223);
  stroke(223);
  line(0,frame,width,frame);
  line(0,height-frame,width,height-frame);
  line(frame,0,frame,height);
  line(width-frame,0,width-frame,height);
  
  pushMatrix();
  translate(0,0,-300);
  fill(123);
  noStroke();
  for(int h=-85; h<gridCounter; h+=grid) {
    for(int w=0; w<width-frame-column+150; w+=grid) {
      circle(w,h,4);
    }
  }
  popMatrix();
  if(gridCounter < height-frame-grid+200) gridCounter+=2*grid;
}


/** 
 * writes text in the margins 
 * @param frame the margin width
 * @param labels array of the text to write in the following order
 *        top, right, bottom right, bottom middle, bottom left, left
 */
void margins(int frame, String[] labels) {
  textSize(16);
  fill(23,234,234);

  pushMatrix();
  translate(frame,frame);
  textAlign(LEFT);
  text(labels[0],75,-5);
  popMatrix();

  pushMatrix();
  translate(width-frame,frame);
  rotate(PI/2);
  textAlign(LEFT);
  text(labels[1],50,-5);
  popMatrix();

  pushMatrix();
  translate(frame,height);
  textAlign(LEFT);
  text(labels[4],5,-5);
  translate(width/2-frame,0);
  textAlign(CENTER);
  text(labels[3],0,-5);
  translate(width/2-frame,0);
  textAlign(RIGHT);
  text(labels[2],-5,-5);
  popMatrix();
 
  pushMatrix();
  translate(frame,frame);
  rotate(-PI/2);
  textAlign(RIGHT);
  text(labels[5],-75,-5);
  popMatrix();
}


/** 
 * returns a String array with the acutal values for printing to
 * column.
 * @param c left or right column 0=left
 */
String[] getValues(int c) {
  if(c == 0) {
    String[] values = {
      "",
      "",
      round(m[s_loc].capModSmooth*1000) + " / " + round(m[s_loc].capModWidth*1000),
      ""+round(m[s_loc].rumpModSmooth*1000) + " / " + round(m[s_loc].rumpModWidth*1000),
      ""+m[s_loc].capSize,
      ""+m[s_loc].elongation,
      ""+(m[s_loc].mutationCycleTarget/m[s_loc].mutationDiv),
      "",
      sensor[s_loc].sid.substring(sensor[s_loc].sid.length()-4),
      sensor[s_loc].getValue("hg")+" % ",
      sensor[s_loc].getValue("temp")+" °C",
      sensor[s_loc].getValue("atm")+" hPa",
      sensor[s_loc].getValue("bvoc")+"ppm",
      sensor[s_loc].getValue("pm25")+" µg/m³",
      sensor[s_loc].getValue("pm10")+" µg/m³",
      "",
      int(frameRate)+"",
      sensor[s_loc].pos+"",
      m[s_loc].baseHue+"°"
    };
    return values;
  } else if(c == 1) {
    String mutationBlock;
    if(m[s_loc].spontaneousMutation) {
      mutationBlock = "open";
    } else {
      mutationBlock = "blocked";
    }
    String[] values = {
      "",
      ""+m[s_loc].gen,
      mutationBlock,
      ""+m[s_loc].lastMutation,
      m[s_loc].lastMutator,
      int((m[s_loc].nextMutation-millis())/1000) +" s",
      ""
    };
    return values;
  } else {
    return null;
  }
}

/** 
 * writes text in two columns into column, each element in the 
 * labels and values arrays is one line
 * @param column the column width
 * @param frame the frame width
 * @param labels an array of labels to print with the values
 * @param values the values to print (has to be same length than labels
 * @param left use left or right side of screen (true = left side)
 */
void column(int column, int frame, String[] labels, String[] values, boolean left) {
  textSize(14);
  textAlign(LEFT);
  fill(23);
  if(left) rect(frame,frame,column,height-2*frame-console.h);
  else rect(width-column-frame,frame,width-frame,height-2*frame);
  fill(23,100,100);
  stroke(223);
  float offset = 0;
  float x = (left) ? frame : width-frame-column;
  for(String t : labels) {
    if(!t.matches("\\#.*")) {
      if(textWidth(t) > offset) offset = textWidth(t);
    }
  }
  offset+=10;
  int col = 0;
  for(int i=0; i<colCounter && i<labels.length; i++) {
    if(labels[i].matches("\\#.*")) {
      if(i==0 && left) textSize(19);
      else textSize(15);
      col++;
      if(i>0) {
        line(x,frame+20*col,x+column,frame+20*col);
        col++;
      }
      text(labels[i].substring(1),x+5,frame+18+20*col);
    } else {
      text(values[i],x+25+offset,frame+18+20*col);    
      text(labels[i],x+5,frame+18+20*col);
      // line(x+20+offset,frame+22+20*(col-1),x+20+offset,frame+22+20*col);
    }
    if(labels[i].matches("\\#.*")) col++;
    // line(x,frame+22+20*col,x+column,frame+22+20*col);
    col++;
  }
  x = (left) ? x+column : x;
  float y = (left) ? height-frame-console.h : height-frame;
  line(x,frame,x,y);

  if(colCounter < labels.length) colCounter+=1;
}


/** 
 * draws the map and position of current sensor to the screen 
 */
void drawMap(int sensor) {
  float x = width-map.width-FRAME_WIDTH;
  float y = height-FRAME_WIDTH-map.height;
  image(map,x,y);
  stroke(100,100,10);
  noFill();
  x += SENSOR_LOCATIONS[sensor].x;
  y += SENSOR_LOCATIONS[sensor].y;
  strokeWeight(3);
  circle(x, y, 20);
  line(x-13,y,x+13,y);
  line(x,y-13,x,y+13);
  strokeWeight(1);
}


/** 
 * returns a formatted date string 
 */
String getDate() {
  SimpleDateFormat simpleDateFormat = new SimpleDateFormat("d MMM YYYY");
  return simpleDateFormat.format(new Date()).toUpperCase();
}


String getDateTime() {
  SimpleDateFormat simpleDateFormat = new SimpleDateFormat("dd-MM-YYYY HH:mm:ss.S");
  return simpleDateFormat.format(new Date()).toUpperCase();
}
