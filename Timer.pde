/** 
 * Class for managing recurring events on a timeframe
 *
 * @version  1.0 22 Oct 2022
 * @author   Juergen Buchinger
 */
 
 class Timer {
   private FloatDict lastCall;
   
   Timer() {
     lastCall = new FloatDict();
   }
   
   
   /**
   * checks if a delay has passed since the last call 
   * @param id id of the delay
   * @param delay dealy time in milliseconds
   */
   boolean delayPassed(String id, float delay) {
     if(lastCall.hasKey(id)) {
       if(millis()-lastCall.get(id) >= delay) {
         lastCall.set(id, lastCall.get(id)+delay);    // do not set lastCall to actual millis() to avoid accumulating latency
         return true;
       } else {
         return false;
       }
     } else {
       lastCall.set(id, millis());
       return true;
     }
   }
   
   void setDelay(String id) {
     lastCall.set(id, millis());
   }
   
   boolean delayPassedOnce(String id, float delay) {
     if(lastCall.hasKey(id)) {
       if(millis()-lastCall.get(id) >= delay) {
         return true;
       } 
     }
     return false;
   }
 }
