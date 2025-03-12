/** 
 * Sensor2 Class reads data from online-resource
 *
 * @version  1.0 22 Oct 2022
 * @author   Juergen Buchinger
 */
  
class Sensor3 {
  JSONArray data;
  String date;
  private String source;
  String sid;
  FloatDict val;
  FloatDict vari;
  FloatDict thres;
  public int pos = 0;
  int id;
    
  /** list of historic standard deviation values to keep track for mutation threshold crossings */
  HashMap<String,FloatList> variHist;
  
  Sensor3(String source_, String sid_, int id_) {
    source = source_;
    sid = sid_;
    id = id_;
    val = new FloatDict();
    vari = new FloatDict();
    thres = new FloatDict();
    if(!fdset) {
      min = new FloatDict();
      max = new FloatDict();
      fdset=true;
    }
    variHist = new HashMap<String,FloatList>();
    console.read("Loading historical data... done.");
    println("loading from "+source+"?sid="+sid);
    data = loadJSONArray(source+"?sid="+sid+"&l="+DATA_HISTORY);
    String[] values = (String[]) data.getJSONObject(0).keys().toArray(new String[data.getJSONObject(0).size()]);
    String cv = "";
    for(int i=0; i<values.length; i++) {
      if(!values[i].equals("time")) {
        val.set(values[i], 0.0);
        min.set(values[i], MAX_FLOAT);
        max.set(values[i], MIN_FLOAT);
        variHist.put(values[i], new FloatList());
        cv += values[i]+", ";
      }
    }
    for(int i=0; i<MUTATION_MEASURES.length; i++) {
      thres.set(MUTATION_MEASURES[i], MUTATION_THRESHOLDS[i]);
    }
    console.read("Values: "+cv.substring(0,cv.length()-2));
    for(int i=0; i<DATA_SKIP; i++) {
      next();
    }
    next();
  }
  
  
  /** 
   * update current values with next value from past data
   * return true if mutation threshold was crossed
   */
  void next() {
    for(String k : val.keyArray()) {
      val.set(k,data.getJSONObject(pos).getFloat(k));
      if(val.get(k) < min.get(k)) min.set(k,val.get(k));
      if(val.get(k) > max.get(k)) max.set(k,val.get(k));
      vari.set(k,stanDev(k));
      variHist.get(k).append(vari.get(k));
    }
    pos++;
  }
  
  
  /** calculates the standard deviation of historic data points */
  float stanDev(String measure) {
    float mean = 0;
    int num = 0;
    for(int i=(pos-STDEV_SET > 0) ? pos-STDEV_SET : 0; i<=pos; i++) {
      mean += data.getJSONObject(i).getFloat(measure);
      num++;
    }
    mean /= num;
    float dev = 0;
    for(int i=(pos-STDEV_SET > 0) ? pos-STDEV_SET : 0; i<=pos; i++) {
      dev += pow(data.getJSONObject(i).getFloat(measure)-mean,2);
    }
    dev /= num;
    dev = pow(dev,0.5);
    return dev;
  }
  
   
  /** 
   * update current values with current values from web resource
   */
  void update() {
    JSONArray d = loadJSONArray(source+"?sid="+sid+"&l=1");
    data.setJSONObject(data.size(), d.getJSONObject(0));
    for(String k : val.keyArray()) {
      val.set(k,d.getJSONObject(0).getFloat(k));
      if(val.get(k) < min.get(k)) min.set(k,val.get(k));
      if(val.get(k) > max.get(k)) max.set(k,val.get(k));
      vari.set(k,stanDev(k));
      variHist.get(k).append(vari.get(k));
    }
    date = d.getJSONObject(0).getString("time");
    pos++;
  } 

   
  float getValue(String k) {
    return(val.get(k));
  }
  
  float getMin(String k) {
    return(min.get(k));
  }
  
  float getMax(String k) {
    return(max.get(k));
  }
  
  float getVari(String k) {
    return vari.get(k);
  }
  
  /** set the min and max values of the datapoints */
  
  void setMinMax(JSONObject min_, JSONObject max_) {
    for(String k : val.keyArray()) {
      println("reading "+k);
      min.set(k,min_.getFloat(k));
      max.set(k,max_.getFloat(k));
    }
  }
  
  // returns a human readable string of all values
  String getValueString() {  
    String all = new String();
    for(String k : val.keyArray()) {
      all += k + ": " + String.format("%04.2f",val.get(k)) + ", ";
    }
    return all;
  }
  
  PShape drawVari(String k, int w, int h) {
    PShape graph = createShape(GROUP);
    float brightness = 0;
    boolean grey = false;
    noFill();
    stroke(233);
    PShape border = createShape(LINE, 0, h, w, h);
    // PShape border2 = createShape(LINE, 0, 0, w, 0);
    graph.addChild(border);
    // graph.addChild(border2);
    FloatList v = variHist.get(k);
    if(graphPos > v.size() && graphPos-v.size() <= 40) {
    } else if(graphPos > v.size()) {
      graphPos=0;
    } 
    float max = (thres.get(k) > v.max()) ? thres.get(k)*1.1 : v.max()*1.1;
    if(!m[s_loc].spontaneousMutation && !k.equals(m[s_loc].lastMutator)) {
      grey=true;
    } 
    // text("mutation threshold", width-COLUMN_WIDTH, height-FRAME_WIDTH-map.height-GRAPH_HEIGHT-5+h-map(thres.get(k), 0, max, 0, h));
    PShape ln = createShape();
    ln.beginShape();
    ln.noFill();
    float x=0;
    float y=0;
    for(int i=0; i<graphPos && i<v.size(); i++) {
      x = map(i,0,v.size(),0,w*0.95);
      y = h - map(v.get(i),0,max,0,h);
      brightness = map(i,0,graphPos, 5,100);
      ln.stroke(23,100,brightness);
      if(grey) ln.stroke(233,0,brightness);
      ln.vertex(x,y);
      if(v.get(i) > thres.get(k) && !mutating && m[s_loc].spontaneousMutation && i >= 30) {
        startMutation(s_loc, k);
        m[s_loc].spontaneousMutation = false;       
      } else if(v.get(i) < thres.get(k) && k == m[s_loc].lastMutator && !m[s_loc].spontaneousMutation && i >= 30) {
        m[s_loc].spontaneousMutation = true;
        m[s_loc].lastMutation = pos;
        clearVariHist();
      }
    }
    ln.endShape();
    graph.addChild(ln);
    fill(23,100,brightness);
    stroke(23,100,brightness);
    PShape circle = createShape(ELLIPSE, x, y, 5, 5);
    graph.addChild(circle);
    stroke(23,100,100);
    fill(23,100,100);
    PShape limit = createShape(LINE, 0, h-map(thres.get(k), 0, max, 0, h), w, h-map(thres.get(k), 0, max, 0, h));
    graph.addChild(limit);
    return graph;
  }
  
  
  /** clears the standard deviation history (will be called after each mutation */
  void clearVariHist() {
    int size = variHist.get("atm").size()-(30+(pos-m[id].lastMutation));
    if(size > variHist.get("atm").size()) size = 30;
    for(Map.Entry me : variHist.entrySet()) {
      for(int i=0; i<size; i++) {
          variHist.get(me.getKey()).remove(0);
      }
    }
  }
}
