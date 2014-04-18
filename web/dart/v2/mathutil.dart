part of Energy2D;

/*
 *   Copyright (C) 2009  The Concord Consortium, Inc.,
 *   25 Love Lane, Concord, MA 01742
 */



/**
 * @author Charles Xie
 *
 */
class MathUtil {

  /** @return true if x is between a and b. */
   static bool between(double a, double b, double x) {
    return x < max(a, b) && x > min(a, b);
  }
/*

   static double getMax(List<double> array) {
    double max = -double.MAX_FINITE;
    for (double x in array) {
      if (x > max)
        max = x;
    }
    return max;
  }

  static double getMin(List<double> array) {
    double min = double.MAX_FINITE;
    for (double x in array) {
      if (x < min)
        min = x;
    }
    return min;
  }

  static double getMax(Matrix<double> array) {
    double max = -double.MAX_FINITE;
    for (List<double> a in array) {
      for (double x in a) {
        if (x > max)
          max = x;
      }
    }
    return max;
  }

  static double getMin(Matrix<double> array) {
    double min = -double.MAX_FINITE;
    for (List<double> a in array) {
      for (double x in a) {
        if (x < min)
          min = x;
      }
    }
    return min;
  }
*/
  static double getAverage(Matrix<double> array) {
    double ave = 0.0;
    for (List<double> a in array) {
      for (double x in a) {
        ave += x;
      }
    }
    return ave / (array.length * array[0].length);
  }

}

