/** 
 * Calculates and evolutes the shape and form of the spherical body's membrane. 
 * The shape is devised from two half spheres ("cap" and "rump"), which can be 
 * modulated by various parameters.
 *
 * The starting shape (geno) that will be modulated into the actual shape (pheno)
 * can be adapted to the given environmental data to bring the actual shape 
 * closer back to a sphere. This will be done in mutate().
 *
 * @version  5.0 25 Oct 2022
 * @author   Juergen Buchinger
 */

public class Membrane {
  /** The shape of the membrane as a pointcloud without deviations, this is the base shape from which to deviate */
  public PShape geno;
  
  /** The shape of the membrane as a pointcloud with deviations, this is the actual current shape */
  public PShape pheno;
    
  /** The shape of the membrane as a pointcloud. Will soon be deprecated */
  public PShape sphere;
  
  /** The shape of the membrane as a mesh */
  public PShape mesh;
  
  /** The name of this specimen, will be created randomly. */
  public String name;
  
  /** the base hue */
  public int baseHue;
  
  /** The vertical radius of the sphere (z-axis) */
  private float radius=250;
    
  /** the number of rings to draw per membrane */
  private int rings = NUM_RINGS;
  
  /** the number of points to draw per ring */
  private int points = NUM_POINTS;
    
  /** Counter for the actual number of rings */
  private int ringCount = rings; 
  
  /** Counter for generation, increments with each mutation */
  public int gen = 1;
  
  /** When was the last mutation? (sensor position) */
  public int lastMutation = 0;
  
  /** What triggered the last mutation? */
  public String lastMutator = "";
  
  /** is the membrane open for spontaneous mutation? */
  public boolean spontaneousMutation = true;
  
  /** time for next mutation */
  public float nextMutation;
  
  /** mutation cycle time (will be adjusted continuously) */
  public int mutationCycle = MUTATION_CYCLE_MIN;
  public int mutationCycleTarget = MUTATION_CYCLE_MIN;
  public int mutationDiv = 1;
  
  /** the time it took the actual mutation to develop (in increments) */
  int mutationTime = 0;
  
  /**
   * The next four variables describe the modulation width and smoothness for random deviation 
   * from the sphere. A higher value equals less smoothness, values beetween 0.01 and 0.02 
   * work best. The can be directly set and read.
   * The actual used value for creating the membrane is cap value for cap, for rump
   * actual value will linearly gravitate towards rump value.
   * 
   * target values can be set and will also be linearly gravitated towards with each call 
   * of pheno()
   * 
   * First is random radius modulation width for cap, tha value is a factor for radius that is the max deviation
   * from radius in both direction, i.e. 0.5 => radius can be 1/4 less or more through modulation
   */
  public float capModWidth=0.0;
  public float capModWidthTarget=0.0;
  public float capModWidthMutationTarget=capModWidthTarget;
  public float capModWidthDiv=1;
  
  /** noise smoothness for cap */
  public float capModSmooth=0.0;
  public float capModSmoothTarget=0.0;
  public float capModSmoothMutationTarget=capModSmoothTarget;
  public float capModSmoothDiv=1;
  
  /** random radius moculation witdth for rump */
  public float rumpModWidth=0.0;
  public float rumpModWidthTarget=0.0;
  public float rumpModWidthMutationTarget=rumpModWidthTarget;
  public float rumpModWidthDiv=1;

  /** noise smoothness for rump */
  public float rumpModSmooth=0.0;
  public float rumpModSmoothTarget=0.0;
  public float rumpModSmoothMutationTarget=rumpModSmoothTarget;
  public float rumpModSmoothDiv=1;
    
  /** 
   * size of cap relativ to whole. 1 = only cap, 0 = no cap 
   * 0.4 - 0.75 are good values
   */
  public float capSize = 0.65;
  public float capSizeTarget = 0.65;
  
  
  /** the increment for targets */
  public float incCapSmooth;
  public float incCapWidth;
  public float incRumpSmooth;
  public float incRumpWidth;
  public float incCapSize;
  public float incElongation;
 
  
  /**
   * coefficient for elongating the rump, is dependent on capSize
   * cap / rump = 1 / elongation ^ capSize
   * good values are 1 < elongation < 16
   * elongation div is divider because we will calculate average over lifespan
   *
   */
  public float elongation = ELONGATION_START;
  public float elongationTarget = ELONGATION_START;
  public float elongationDiv = 1;
  
  /** 
   * The longitudinal memory stores a recollection of a data point over
   * as much iterations as the membrane has rings. It will additionally 
   * modulate each ring
   */
  public float[] longMem = new float[rings+MOVING_AVERAGE];
  public float[] longMemMA = new float[rings]; // with moving average
  
  
  /** modulation width for longitudinal memory */
  public float longMemWidth = 0.0;
  
  /** 
   * rumpDecenter is a Vector that points to the end of the rump
   * as displacement from the vertical center of the sphere
   * the rump will linearly gravitate towards the displacement
   */
  public PVector rumpDecenter = new PVector(0,0);
  
  
  /** 
   * The starting points to use for moving in the noise space
   * This is important to put the form into the positiv quarter of the noise space
   * otherwise the modulations will be symmetrical around the zero crossings.
   * We will use random values to make each instance different.
   * Least offset must be 1 * radius plus we account for modulation,
   * z-Axis is more because of elongation
   */
  private float noiseX0 = random(3*radius,12*radius);
  private float noiseY0 = random(3*radius,12*radius);
  private float noiseZ0 = random(6*radius,12*radius);
  
  
  /** how fast to move through the noise space (should be accessible directly?) */
  public float evSpeed = SHIFT_SPEED;
  
  
  /** the id corresponding to the sensor and s_loc in main */
  private int id;
  
  
  /** 
   * class constructor
   */
  Membrane(int id_) { 
    id=id_;
    sphere();
    geno = sphere;
    char[] n = new char[4];
    for(int i=0; i<4; i++) {
      n[i] = char(int(random(26)+65));
    }
    name = new String(n);
    nextMutation = millis()+mutationCycle*1000;
  }
  
  /** 
   * class constructor
   */
  Membrane(int id_, JSONObject geno_) { 
    id=id_;
    sphere();
    name = geno_.getString("name");
    gen = geno_.getInt("gen");
    baseHue = geno_.getInt("hue");
    rings = geno_.getInt("rings");
    points = geno_.getInt("points");
    JSONArray vertices = geno_.getJSONArray("vertices");
    nextMutation = millis()+mutationCycle*1000;
    lastMutation = geno_.getInt("lastMutation");
    geno = createShape();
    geno.beginShape(POINTS);
    for(int i=0; i<vertices.size(); i++) {
      JSONObject v = vertices.getJSONObject(i);
      geno.stroke(color(baseHue, v.getInt("s"), 140));
      geno.vertex(v.getFloat("x"), v.getFloat("y"), v.getFloat("z"));
    }
  }
  
  
  /** 
   * Calculates the point cloud of the base form of the membrane, this will be used to deviate from.
   * The membranes base form is an elongated sphere. It is elongated along the z-Axis. 
   * It is drawn by drawing circles with different radiusses around the z-Axis. 
   * We use one Vector to move the cirles along the z-Axis and one Vector to draw the circles.
   */
  void sphere() {
    float rumpElongation = pow(elongation, capSize);
    int capRings = int(rings*capSize);
    int a;
    sphere = createShape();
    sphere.beginShape(POINTS);
    sphere.stroke(123);
    PVector axial = new PVector(0,radius);
    for(a=0; a < capRings; a++) {
      PVector radial = new PVector(axial.x,0);
      for(int b = 0; b < points; b++) {
        PVector r = new PVector(radial.x,radial.y,axial.y);
        sphere.vertex(r.x,r.y,r.z);
        radial.rotate(2*PI/points);
      }
      axial.rotate(PI/rings);
    }
    float yOff = sphere.getVertex(sphere.getVertexCount()-1).z * (rumpElongation - 1); 
    for(; a < rings; a++) {
      PVector radial = new PVector(axial.x,0);
      for(int b = 0; b < points; b++) {
        PVector r = new PVector(radial.x,radial.y,axial.y * rumpElongation - yOff);
        sphere.vertex(r.x,r.y,r.z);
        radial.rotate(2*PI/points);
      }
      axial.rotate(PI/rings);
    }
    sphere.endShape();    
  }
  
  
  /**
   * loops through all the vertices of the cloud and deviates from them according 
   * to modulation width and noise values. This should be called each time the 
   * data updates or, if using shiftY it should be called in the draw loop
   */
  void pheno() {
    int capRings = int(geno.getVertexCount()/points * capSize);
    float modSmooth = capModSmooth;
    float modSmoothInc = capModSmooth > rumpModSmooth ? SMOOTH_TRANS_COEFF : 2-SMOOTH_TRANS_COEFF;

    pheno = createShape();
    pheno.beginShape(POINTS);

    int i = 0;
    for(i = 0; i<capRings*points; i++) {
      PVector v = geno.getVertex(i);
      PVector nv = new PVector(v.x,v.y,v.z);
      nv.mult(capModSmooth);
      // v.mult((1-capModWidth/2)+(noise(nv.x+noiseX0,nv.y+noiseY0,nv.z+noiseZ0)+longMemMA[i/points])/2*capModWidth);
      v.mult((1-capModWidth/2)+(noise(nv.x+noiseX0,nv.y+noiseY0,nv.z+noiseZ0))*capModWidth);
      // v.mult((1-capModWidth/2)+longMemMA[i/points]*longMemWidth);
      // pheno.stroke(color(baseHue+(widthHue/2-widthHue*noise(nv.x+noiseX0,nv.y+noiseY0,nv.z+noiseZ0)),40,40));
      pheno.stroke(color(baseHue,100*noise(nv.x+noiseX0,nv.y+noiseY0,nv.z+noiseZ0),40));
      pheno.vertex(v.x,v.y,v.z);
    }
    /*println("points-1: "+(points-1)/points);
    println("points: "+(points)/points);
    println("points+1: "+(points+1)/points);*/
    
    // println();
    // rrPVector elo = new PVector(0,0,-pow(elongation, capSize));

    for(; i<geno.getVertexCount(); i++) {
      if(i % points == 0) {
        if(abs(modSmooth*modSmoothInc-rumpModSmooth) < abs(modSmooth-rumpModSmooth)) {
          modSmooth *= modSmoothInc;
        }
      }
      PVector v = geno.getVertex(i);
      PVector v2 = new PVector(v.x,v.y,v.z);
      PVector nv = new PVector(v.x,v.y,v.z);
      nv.mult(modSmooth);
      // v2.sub(elo);
      v2.mult((1-rumpModWidth/2)+noise(nv.x+noiseX0,nv.y+noiseY0,nv.z+noiseZ0)*rumpModWidth);
      
      // v2.mult((1-capModWidth/2)+longMemMA[i/points]*longMemWidth);
      // v2.mult((1-rumpModWidth/2)+(noise(nv.x+noiseX0,nv.y+noiseY0,nv.z+noiseZ0)+longMemMA[i/points])/2*rumpModWidth);
      // v2.add(elo);
      pheno.stroke(color(baseHue,100*noise(nv.x+noiseX0,nv.y+noiseY0,nv.z+noiseZ0),40));
      pheno.vertex(v2.x,v2.y,v2.z);
    }
    pheno.endShape();
    meetTargets();
  }
  
  
  /** 
   * Checks if there are targets for the modulation coefficients set
   * and if they differ from the actual values, increments them towards 
   * the targets.
   */
  void meetTargets() {
    if(abs(capModWidth - capModWidthTarget) > incCapWidth) {
      capModWidth = capModWidth > capModWidthTarget ? capModWidth-incCapWidth : capModWidth+incCapWidth;
    }
    if(abs(capModSmooth - capModSmoothTarget) > incCapSmooth) {
      capModSmooth = capModSmooth > capModSmoothTarget ? capModSmooth-incCapSmooth : capModSmooth+incCapSmooth;
    }
    if(abs(rumpModWidth - rumpModWidthTarget) > incRumpWidth) {
      rumpModWidth = rumpModWidth > rumpModWidthTarget ? rumpModWidth-incRumpWidth : rumpModWidth+incRumpWidth;
    }
    if(abs(rumpModSmooth - rumpModSmoothTarget) > incRumpSmooth) {
      rumpModSmooth = rumpModSmooth > rumpModSmoothTarget ? rumpModSmooth-incRumpSmooth : rumpModSmooth+incRumpSmooth;
    }
    if(abs(capSize - capSizeTarget) > incCapSize) {
      capSize = capSize > capSizeTarget ? capSize-incCapSize : capSize+incCapSize;
    }
  }
  
  
  /** 
   * This method represents a generation transition. The genotype will be overwritten with a reaction
   * to the current phenotype to an inverted shape of future deviations in order to compensate for them 
   * and return to a shape most close to a sphere.
   * Draws the new Phenotype slowly for effect and returns true when finished.
   * This is a preliminary function and will be replaced by an AI assisted guess. 
   * FIXME: auch in cap und rump aufteilen und mit elongation difference elongieren.
   */
   boolean mutate() {
     if(ringCounter > rings) {
       return true;
     }
     float elongOld = pow(elongation, capSize);
     float elong = pow(elongationTarget, capSize);
     elongation = elongationTarget;
     // elong = (elong+elongOld)/2;
     /*println("elongation="+elongation);
     println("elongationTarget="+elongationTarget);
     println("elongNew="+elong);
     println("elongOld="+elongOld);*/
     elong = 1 + elong - elongOld;
     // println("elongDiff="+elong);
     int capRings = int(rings * capSize);
     PShape genX = createShape();
     genX.beginShape(POINTS);
     genX.stroke(233);
     int i;
     // OLD MUTATE
     for(i=0; i < ringCounter*points && i < capRings*points; i++) {
       PVector v = sphere.getVertex(i);
       v.setMag(sphere.getVertex(i).mag() + (sphere.getVertex(i).mag() - pheno.getVertex(i).mag()));
       v.setMag((geno.getVertex(i).mag()+v.mag())/2);
       // if(i > rings * capSize * points && v.z > 0) v.z = 0;
       genX.vertex(v.x,v.y,v.z);
     }
     float yOff = genX.getVertex(genX.getVertexCount()-1).z * (elong - 1); 

     for(; i < ringCounter*points; i++) {
       PVector v = sphere.getVertex(i);
       v.setMag(sphere.getVertex(i).mag()+(sphere.getVertex(i).mag()-pheno.getVertex(i).mag()));
       genX.vertex(v.x,v.y,v.z * elong - yOff);
     }
     
     // NEW MUTATE
     /*for(i=0; i < ringCounter*points && i < capRings*points; i++) {
       PVector v = pheno.getVertex(i);
       genX.vertex(v.x,v.y,v.z);
     }
     float yOff = genX.getVertex(genX.getVertexCount()-1).z * (elong - 1); 

     for(; i < ringCounter*points; i++) {
       PVector v = pheno.getVertex(i);
       genX.vertex(v.x,v.y,v.z * elong - yOff);
     }*/
     
     // fill the not yet mutated rings with the old genotype
     for(; i<geno.getVertexCount(); i++) {
       PVector v = geno.getVertex(i);
       genX.vertex(v.x,v.y,v.z);
     }
     genX.endShape();
     geno = genX;
     
     ringCounter++;

     return false;
   }
   
   
   /** 
    * shifts the longitudinal memory and inserts a new value at the beginning
    * the new value is a moving average over 10 values
    * @param value new value to insert
    */
   void memorize(float value) {
     for(int i=longMem.length-1; i>0; i--) {
       longMem[i] = longMem[i-1];
     }
     longMem[0] = value;
     float ma = 0;
     for(int i=0; i<MOVING_AVERAGE; i++) {
       ma += longMem[i];
     }
     ma /= MOVING_AVERAGE;
     
     for(int i=longMemMA.length-1; i>0; i--) {
       longMemMA[i] = longMemMA[i-1];
     }
     longMemMA[0] = ma;
   }
   
  /** 
   * DEPRECATED: Is replaced by sphere() and pheno()
   * calculates the membrane as a point cloud. Replaces evolute() with Vectors 
   * The membranes base form is a sphere, but for the sake of direction, we imagine it
   * as an elongated sphere. It is elongated along the z-Axis. It is drawn by drawing 
   * circles with different radiusses around the z-Axis. We use one Vector to move the 
   * cirles along the z-Axis and one Vector to draw the circles.
   * To these circles we apply the deviations based on 3D-perlin noise.
   * FIXME: make it so that rings is really the amount of rings, not less becuase of elongation
   */
  void calculate() {
    sphere = createShape();
    sphere.beginShape(POINTS);
    ringCount=0;
    float rumpElongation = pow(elongation, capSize);

    int capRings = int(capSize * rings / (rumpElongation - capSize * rumpElongation + capSize));
    int rumpRings = rings - capRings;
    
    
    PVector axial = new PVector(0,radius);
    // int pnum=0;
    // paint cap of membrane 
    for(int a = 0; a < capRings; a++) {
      PVector radial = new PVector(axial.x,0);
      for(int b = 0; b < points; b++) {
        PVector nv = new PVector(radial.x,radial.y,axial.y);
        nv.mult(capModSmooth);
        PVector r = new PVector(radial.x,radial.y,axial.y);
        r.mult((1-capModWidth/2)+noise(nv.x+noiseX0,nv.y+noiseY0,nv.z+noiseZ0)*capModWidth);
        sphere.stroke(color(90+180*noise(nv.x+noiseX0,nv.y+noiseY0,nv.z+noiseZ0),40,40));
        // sphere.stroke(color(0,0,25+30*noise(nv.x+noiseX0,nv.y+noiseY0,nv.z+noiseZ0)));
        sphere.vertex(r.x,r.y,r.z);
        radial.rotate(2*PI/points);
        // pnum++;
      }
      axial.rotate((PI*capSize)/capRings);
      ringCount++;
    }
    
    // paint rump of membrane
    float yOff = axial.y * (rumpElongation-1); 
    float modSmooth = capModSmooth;
    float modSmoothInc = capModSmooth > rumpModSmooth ? SMOOTH_TRANS_COEFF : 2-SMOOTH_TRANS_COEFF;
    for(int a = 0; a < rumpRings; a++) {
      PVector radial = new PVector(axial.x,0);
      for(int b = 0; b < points; b++) {
        PVector nv = new PVector(radial.x,radial.y,axial.y);
        nv.mult(modSmooth);
        PVector r = new PVector(radial.x,radial.y,axial.y * rumpElongation - yOff);
        r.mult((1-rumpModWidth/2)+noise(nv.x+noiseX0,nv.y+noiseY0,nv.z+noiseZ0)*rumpModWidth);
        sphere.stroke(color(90+180*noise(nv.x+noiseX0,nv.y+noiseY0,nv.z+noiseZ0),40,40));
        // sphere.stroke(color(0,0,25+30*noise(nv.x+noiseX0,nv.y+noiseY0,nv.z+noiseZ0)));
        sphere.vertex(r.x,r.y,r.z);
        radial.rotate(2*PI/points);
      }
      axial.rotate((PI*(1-capSize))/rumpRings);
      ringCount++;
      if(abs(modSmooth*modSmoothInc-rumpModSmooth) < abs(modSmooth-rumpModSmooth)) {
        modSmooth *= modSmoothInc;
      }
    }
    sphere.endShape();    
  }

  
  /** 
   * save the membrane as a point cloud .obj-File
   * @param file the file name to save in without extension
   */
  void saveWaveform(String file) {
    PrintWriter output = createWriter("data/"+file+".obj");
    for (int n=0; n<pheno.getVertexCount(); n++) {
      PVector v = pheno.getVertex(n);
      output.println("v "+v.x+" "+v.y+" "+v.z);
    }
    console.read("Saving OBJ-Waveform with "+NUM_RINGS+" rings of each "+NUM_POINTS+" points ("+pheno.getVertexCount()+" vertices)...");
    float t = millis();
    for(int r=0; r<NUM_RINGS-1; r++) {
      for(int p=0; p<NUM_POINTS-1; p++) {
        int a = r*NUM_POINTS+p;
        int b = r*NUM_POINTS+p+1;
        int c = (r+1)*NUM_POINTS+p;
        int d = (r+1)*NUM_POINTS+p+1;
        output.println("f "+(a+1)+" "+(b+1)+" "+(c+1));  // all plus one because vertex index starts at 1
        output.println("f "+(b+1)+" "+(c+1)+" "+(d+1));        
      }    
      // close the circle
      int a = r*NUM_POINTS+NUM_POINTS-1;
      int b = r*NUM_POINTS;
      int c = (r+1)*NUM_POINTS+NUM_POINTS-1;
      int d = (r+1)*NUM_POINTS;
      output.println("f "+(a+1)+" "+(b+1)+" "+(c+1));  // all plus one because vertex index starts at 1
      output.println("f "+(b+1)+" "+(c+1)+" "+(d+1));              
    }
    t = millis() - t;
    console.read("...done in "+t+" milliseconds.");
    output.flush();
    output.close();  
  }
  
  
  /** 
   * save the membrane as a point cloud .obj-File in two parts
   * cap and rump
   * @param file the file name to save in without extension
   * @param cap whether to save cap or rump
   */
  void saveWaveformPart(boolean cap) {
    int maxRings = NUM_RINGS;
    int minRings = 0;
    if(cap) maxRings = int(NUM_RINGS*capSize);
    else minRings = int(NUM_RINGS*capSize);
    String cp = (cap) ? "cap" : "rump";
    PrintWriter output = createWriter("models/"+name+"_"+cp+".obj");
    console.read("Saving OBJ_Waveform with "+pheno.getVertexCount()+" vertices...");
    console.read("Writing vertices for "+minRings*NUM_POINTS+" -> "+maxRings*NUM_POINTS + " ... ");
    float t = millis();
    for (int n=minRings*NUM_POINTS; n<maxRings*NUM_POINTS; n++) {
      PVector v = pheno.getVertex(n);
      output.println("v "+v.x+" "+v.y+" "+v.z);
    }
    for(int r=minRings; r<maxRings-1; r++) {
      for(int p=0; p<NUM_POINTS-1; p++) {
        int a = (r-minRings)*NUM_POINTS+p;
        int b = (r-minRings)*NUM_POINTS+p+1;
        int c = (r-minRings+1)*NUM_POINTS+p;
        int d = (r-minRings+1)*NUM_POINTS+p+1;
        output.println("f "+(a+1)+" "+(b+1)+" "+(c+1));  // all plus one because vertex index starts at 1
        output.println("f "+(b+1)+" "+(c+1)+" "+(d+1));        
      }    
      // close the circle
      int a = (r-minRings)*NUM_POINTS+NUM_POINTS-1;
      int b = (r-minRings)*NUM_POINTS;
      int c = (r-minRings+1)*NUM_POINTS+NUM_POINTS-1;
      int d = (r-minRings+1)*NUM_POINTS;
      output.println("f "+(a+1)+" "+(b+1)+" "+(c+1));  // all plus one because vertex index starts at 1
      output.println("f "+(b+1)+" "+(c+1)+" "+(d+1));              
    }
    output.flush();
    output.close();  
    t = millis() - t;
    console.add("done in " + t + " ms");   
  }
  
  
  /** 
   * save the genotype as a json-File and update specimen index
   * @param file the file name to save in without extension
   */
  void saveGeno() {
    console.read("Saving genotype of "+name+" as Waveform with "+NUM_RINGS+" rings of each "+NUM_POINTS+" points ("+pheno.getVertexCount()+" vertices)... ");
    JSONObject ind = loadJSONObject("history/index.json");
    JSONArray index = ind.getJSONArray("specimens");
    boolean found = false;
    for(int i=0; i<index.size(); i++) {
      if(index.getJSONObject(i).getString("name").equals(name)) {
        if(index.getJSONObject(i).getInt("gen") < gen) {
          index.getJSONObject(i).setInt("gen", gen);
        }
        found = true;
      }
    }
    if(!found) {
      JSONObject mem = new JSONObject();
      mem.setString("name", name);
      mem.setInt("gen", gen);
      index.setJSONObject(index.size(), mem);
    }
    float t = millis();
    JSONArray vertices = new JSONArray();
    for (int n=0; n<pheno.getVertexCount(); n++) {
      PVector v = pheno.getVertex(n);
      color c = pheno.getStroke(n);
      JSONObject ve = new JSONObject();
      ve.setFloat("s", saturation(c));
      ve.setFloat("x", v.x);
      ve.setFloat("y", v.y);
      ve.setFloat("z", v.z);
      vertices.setJSONObject(n, ve);
    }
    JSONObject tmin = new JSONObject();
    JSONObject tmax = new JSONObject();
    for(String k : sensor[id].val.keyArray()) {
      tmin.setFloat(k, min.get(k));
      tmax.setFloat(k, max.get(k));
    }
    JSONObject dna = new JSONObject();
    dna.setString("name", name);
    dna.setInt("gen", gen);
    dna.setInt("hue", baseHue);
    dna.setInt("rings", rings);
    dna.setInt("points", points);
    dna.setJSONArray("vertices", vertices);
    dna.setInt("lastMutation", lastMutation);
    dna.setString("mutator", lastMutator);
    dna.setInt("mutationTime", mutationTime);
    dna.setJSONObject("min", tmin);
    dna.setJSONObject("max", tmax);
    saveJSONObject(dna, "history/"+name+"/"+gen+".json");
    ind.setJSONArray("specimens",index);
    saveJSONObject(ind, "history/index.json");
    t = millis() - t;
    console.add("done in "+t+" milliseconds.");
  }
  
  
  /** 
   * save the membrane as a point cloud .obj-File
   * @param file the file name to save in without extension
   */
  void saveSTL(String file, boolean cap) {
    int maxRings = NUM_RINGS;
    int minRings = 0;
    if(cap) maxRings = int(NUM_RINGS*capSize);
    else minRings = int(NUM_RINGS*capSize);
    PrintWriter output = createWriter("data/"+file+".stl");
    output.println("solid epizoon");
    for(int r=minRings; r<maxRings-1; r++) {
      for(int p=0; p<NUM_POINTS-1; p++) {
        PVector va = pheno.getVertex(r*NUM_POINTS+p);
        PVector vb = pheno.getVertex(r*NUM_POINTS+p+1);
        PVector vc = pheno.getVertex((r+1)*NUM_POINTS+p);
        PVector vd = pheno.getVertex((r+1)*NUM_POINTS+p+1);
        PVector vn1 = calculateNormal(va,vb,vc);
        PVector vn2 = calculateNormal(vb,vc,vd);
        
        Formatter a = new Formatter();
        Formatter b = new Formatter();
        Formatter c = new Formatter();   
        Formatter d = new Formatter();
        Formatter n1 = new Formatter();   
        Formatter n2 = new Formatter();
        
        a.format("%e %e %e",va.x, va.y, va.z);
        b.format("%e %e %e",vb.x, vb.y, vb.z);
        c.format("%e %e %e",vc.x, vc.y, vc.z);
        d.format("%e %e %e",vd.x, vd.y, vd.z);
        n1.format("%e %e %e",vn1.x, vn1.y, vn1.z);
        n2.format("%e %e %e",vn2.x, vn2.y, vn2.z);

        output.println("  facet normal "+n1);
        output.println("    outer loop");
        output.println("      vertex "+a);
        output.println("      vertex "+b);
        output.println("      vertex "+c);
        output.println("    endloop");
        output.println("  endfacet");
        
        output.println("  facet normal "+n2);
        output.println("    outer loop");
        output.println("      vertex "+b);
        output.println("      vertex "+c);
        output.println("      vertex "+d);
        output.println("    endloop");
        output.println("  endfacet");    
        
        n1.close();
        n2.close();
        a.close();
        b.close();
        c.close();
        d.close();
      }    
      // close the circle
    
      PVector va = pheno.getVertex(r*NUM_POINTS+NUM_POINTS-1);
      PVector vb = pheno.getVertex(r*NUM_POINTS);
      PVector vc = pheno.getVertex((r+1)*NUM_POINTS+NUM_POINTS-1);
      PVector vd = pheno.getVertex((r+1)*NUM_POINTS);
      PVector vn1 = calculateNormal(va,vb,vc);
      PVector vn2 = calculateNormal(vb,vc,vd);
        
      Formatter a = new Formatter();
      Formatter b = new Formatter();
      Formatter c = new Formatter();   
      Formatter d = new Formatter();
      Formatter n1 = new Formatter();   
      Formatter n2 = new Formatter();
      
      a.format("%e %e %e",va.x, va.y, va.z);
      b.format("%e %e %e",vb.x, vb.y, vb.z);
      c.format("%e %e %e",vc.x, vc.y, vc.z);
      d.format("%e %e %e",vd.x, vd.y, vd.z);
      n1.format("%e %e %e",vn1.x, vn1.y, vn1.z);
      n2.format("%e %e %e",vn2.x, vn2.y, vn2.z);

      output.println("  facet normal "+n1);
      output.println("    outer loop");
      output.println("      vertex "+a);
      output.println("      vertex "+b);
      output.println("      vertex "+c);
      output.println("    endloop");
      output.println("  endfacet");
      
      output.println("  facet normal "+n2);
      output.println("    outer loop");
      output.println("      vertex "+b);
      output.println("      vertex "+c);
      output.println("      vertex "+d);
      output.println("    endloop");
      output.println("  endfacet");    
      
      n1.close();
      n2.close();
      a.close();
      b.close();
      c.close();
      d.close();
    }
    output.println("endsolid epizoon");
    output.flush();
    output.close();  
  }
  
  
  /** 
   * Calculate normals for the mesh
   * FIXME this is not yet working but only calculating placeholders
   */
  PVector calculateNormal(PVector a, PVector b, PVector c) {
    PVector n;
    a.sub(c);
    b.sub(c);
    n = a.cross(b);
    n.normalize();
    return n;
  }
  
  /** 
   * convert the point cloud membrane to a mesh
   */
  void convertToTriangles() {
    PShape all = createShape(GROUP);
    for(int z=0; z<ringCount-1; z+=1) {
      PShape circle = createShape();
      circle.beginShape(TRIANGLE_STRIP);
      circle.noStroke();
      for(int r=0; r<points; r++) {
        PVector v = pheno.getVertex(z*points+r);
        color c = pheno.getStroke(z*points+r);
        circle.fill(c);
        circle.vertex(v.x,v.y,v.z);
        v = pheno.getVertex((z+1)*points+r);
        circle.vertex(v.x,v.y,v.z);
      }
      PVector v = pheno.getVertex(z*points);
      circle.vertex(v.x,v.y,v.z);
      v = pheno.getVertex((z+1)*points);
      circle.vertex(v.x,v.y,v.z);
      circle.endShape();
      all.addChild(circle);
    }
    mesh = all;
  }
  
  /**
   * Shift the noise deviation readings in the noise space (along Y-axis?)
   */
  void shiftY() {
    noiseZ0+=evSpeed;
  }

  
  /** 
   * Returns a PShape that represents the coordinate system of the membrane as well as
   * a key to read it
   */
  PShape drawCoordinateSystem() {
    PShape cs = createShape();
    cs. beginShape(LINES);
    cs.stroke(0,100,100);
    cs.vertex(0,0,-800);
    cs.vertex(0,0,300);
    cs.stroke(105,100,100);
    cs.vertex(0,-300,0);
    cs.vertex(0,300,0);
    cs.stroke(210,100,100);
    cs.vertex(-300,0,0);
    cs.vertex(300,0,0);
    cs.endShape();
    return cs;
  }
}
