/** all settings can be found here */

/** 
 * if this is false, the index with specimens and mutations will be read, if true
 * new specimens will be created (this will delete any previous index file, but 
 * not the saved specimen-mutation-files 
 */
public static final boolean INDEX_REWRITE = true;


/** 
 * the following settings determine how the membrane is affected by the
 * different changes in environmental values
 */ 
 
/**
 * smoothness transition coefficient (new) 
 * determines how fast we transition from cap to rump smoothness.
 * It is a factor and will be inverted (2-MOD_TRANS_INC) if neccessary
 * around 0.97 - 1 are good values
 */
public static final float SMOOTH_TRANS_COEFF = 0.99;

/** absolute min and max values for rump smoothness */
public static final float RUMP_MOD_SMOOTH_MIN = 0.001;
public static final float RUMP_MOD_SMOOTH_MAX = 0.02;
 
/** absolute min and max values for cap smoothness */
public static final float CAP_MOD_SMOOTH_MIN = 0.001;
public static final float CAP_MOD_SMOOTH_MAX = 0.02;

/** absolute min and max values for rump modulation with */
public static final float RUMP_MOD_WIDTH_MIN = 0.2;
public static final float RUMP_MOD_WIDTH_MAX = 0.9;
 
/** absolute min and max values for cap modulation wdith */
public static final float CAP_MOD_WIDTH_MIN = 0.2;
public static final float CAP_MOD_WIDTH_MAX = 0.9;

/** absolute min and max values for long mem modulation width */
public static final float LONG_MEM_MOD_WIDTH_MIN = 0.05;
public static final float LONG_MEM_MOD_WIDTH_MAX = 0.8;

/** moving average for longitudinal memory equals modulation smoothness */
public static final int MOVING_AVERAGE = 3;

/** standard deviation set (= how many values to go back for calculation) */
public static final int STDEV_SET = 30;

/** how much datapoints to load initially must be more or equal than STDEV_SET */
public static final int DATA_HISTORY = 10000;

/** 
 * how mouch data points to skip at load (if smaller than DATA_HISTORY, we can 
 * iterate faster than SENSOR_UPDATES. Use this for testing purposes
 */
public static final int DATA_SKIP = 1000;

/** absolute min and max values for cap size (relative to whole) */
public static final float CAP_SIZE_MIN = 0.4;
public static final float CAP_SIZE_MAX = 0.75;

/** 
 * absolute min and max values for rump elongation
 * plus the starting value because it affects sphere directly and is 
 * adapted each mutation for geno
 */
public static final float ELONGATION_START = 4;
public static final float ELONGATION_MAX = 16;
public static final float ELONGATION_MIN = 1;

/** 
 * limits for exposure of the different environmental values
 * these are taken from WHO recommendations and limits */
public static final float MAX_PM25 = 20;
public static final float MIN_PM25 = 0;
public static final float MAX_PM10 = 20;
public static final float MIN_PM10 = 0;

/** number of rings for membrane */
public static final int NUM_RINGS = 300;      //300

/** number of points per ring for membrane */
public static final int NUM_POINTS = 200;    // 200

/** base hues for coloring */
public static final int[] BASE_HUE = {
  54,
  166,
  33,
  317,
  197
};

/** rotation of form around x-Axis (initial rotation if rotate is true */
public static final float INITIAL_X_ROTATION = 1.1;

/** the speed for shifting through noise space */
public static final float SHIFT_SPEED = 0.005;

/** width of the drawn frame on the screen */
public static final int FRAME_WIDTH = 25;

/** width of the columns on the sides of the screen in % */
public static final float COLUMN_WIDTH_ = 0.2;

/** heihgt of the standard deviation graph */
public static final int GRAPH_HEIGHT = 160;

/** height of console output in percent */
public static final float CONSOLE_HEIGHT_ = 0.17;

/** time in seconds for rotating between specimens */
public static final int ROTATION_TIME = 120;

/** time in seconds for updating sensors */
public static final int SENSOR_UPDATES = 1;

/** max and min time to initiate planned mutation after last mutation in seconds */
public static final int MUTATION_CYCLE_MAX = 4 * 60 * 60;
public static final int MUTATION_CYCLE_MIN = 60 * 60;

/** min max values for vari for mutation cycle */
public static final float VARI_MIN = 0.0;
public static final float VARI_MAX = 2.0;

/** when standard deviation crosses this threshold, a mutation occurs */
public static final float[] MUTATION_THRESHOLDS = {
  2.2,
  0.5,
  0.5,
  1,
  2.0,
  2.2
};

/** on which measures shall we test for mutation threshold? */
public static final String[] MUTATION_MEASURES = {
  "hg",
  "temp",
  "atm",
  "bvoc",
  "pm25",
  "pm10"
};

/** human readable labels for mutation thresholds */
public static final String[] MUTATION_LABELS = {
    "relative humidity",
    "temperature",
    "atmospheric pressure",
    "volatile organic compounds",
    "particulate matter (< 2.5 µm)",
    "particulate matter (< 10 µm)"
};

/** sensor locations on map coordinates */
public static final PVector[] SENSOR_LOCATIONS = {
  new PVector(1010, 378)
};

/** sensor coordinates in real life */
public static final String[] SENSOR_COORDINATES = {
  "47°04’14”N 8°16’49”E"
};

/** sensor ids */
public static final String[] SENSOR_IDS = {
  "eui-3534333052307e0c",        // WILG-blue (street)
};

/** 
 * DEPRECATED: will be read directly from JSON Array
 * the values to read from json ressource (later from sensor) 
 */
String[] DATA_POINTS = {
  "time",
  "hg",
  "temp",
  "atm",
  "eco2",
  "bvoc",
  "iaq",
  "iaq_acc",
  "pm25",
  "pm10"
};
