/** 
 * Manages a console for graphic interface
 *
 * @version  1.2 26 Oct 2022
 * @author   Juergen Buchinger
 */

class Console {
  StringList msg;
  StringList ts;  //timestamps
  int size = 14;
  int lineHeight = 20 ;
  int h = int(height*CONSOLE_HEIGHT_);
   
  Console() {
    msg = new StringList();
    ts = new StringList();
    println("Starting console (h="+h+")... done.");
  }
   
   
  /** adds to last line in cosole buffer */
  void add(String msg_) {
    msg.set(msg.size()-1, msg.get(msg.size()-1)+msg_);
  }
  
  /** adds a line and timestamp to cosole buffer */
  void read(String msg_) {
    msg.append(msg_);
    ts.append(getDateTime());
  }
   
  /** writes buffer to screen */
  void write(int frame) {
    textSize(size);
    textAlign(LEFT,TOP);
    fill(25);
    rect(frame,height-frame-h,width-2*frame-COLUMN_WIDTH,height-frame);
    stroke(233);
    line(frame,height-frame-h,width-2*frame-COLUMN_WIDTH,height-frame-h);
    fill(23,100,100);
    for(int i=h/lineHeight; i>0; i--) {
      if(i<msg.size()) {
        text(ts.get(ts.size()-i) + " -> " + msg.get(msg.size()-i),frame+5,height-frame-h+20*(h/lineHeight-i));
      }
    }
  }
}
