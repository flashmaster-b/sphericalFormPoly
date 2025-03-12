/** 
 * Sensor2 Class reads data from json-resource
 *
 * @version  1.0 04 Oct 2022
 * @author   Juergen Buchinger
 */
  
class Sensor2 {
  JSONArray data;
  String date;
  FloatDict val;
  FloatDict max;
  FloatDict min;
  public int pos = 0;
  
  Sensor2(String[] values, String source) {
    val = new FloatDict();
    min = new FloatDict();
    max = new FloatDict();
    for(int i=0; i<values.length; i++) {
      val.set(values[i], 0.0);
      min.set(values[i],MAX_FLOAT);
      max.set(values[i],MIN_FLOAT);
    }
    data = loadJSONArray(source);
    for(int i=0; i<100; i++) update();     // to get different min/max values to avoid NaN from map(...)
  }
  
  
  /** 
   * update current values with next item in array
   */
  void update() {
    for(String k : val.keyArray()) {
      val.set(k,data.getJSONObject(pos).getFloat(k));
      if(val.get(k) < min.get(k)) min.set(k,val.get(k));
      if(val.get(k) > max.get(k)) max.set(k,val.get(k));
    }
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
  
  // returns a human readable string of all values
  String getValueString() {  
    String all = new String();
    for(String k : val.keyArray()) {
      all += k + ": " + String.format("%04.2f",val.get(k)) + ", ";
    }
    return all;
  }
}
