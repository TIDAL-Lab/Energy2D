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
    bool between (double a, double b, double x) {
    return x < max(a, b) && x > min(a, b);
  }


  static double getMaxNum(List<double> array) {
    double max = -double.MAX_FINITE;
    for (double x in array) {
      if (x > max)
        max = x;
    }
    return max;
  }


  static double getMinNum(List<double> array) {
    double min = double.MAX_FINITE;
    for (double x in array) {
      if (x < min)
        min = x;
    }
    return min;
  }

  static double getmax(Matrix<double> m) {
    double max = -double.MAX_FINITE;
    for (int i=0; i<m.rows; i++) {
      for (int j=0; j<m.cols; j++) {
        if (m[i][j] > max) {
          max = m[i][j];
        }
      }
    }
    return max;
  }

  static double getMin(Matrix<double> m) {
    double min = double.MAX_FINITE;
    for (int i=0; i<m.rows; i++) {
      for (int j=0; j<m.cols; j++) {
        if (m[i][j] < min) {
          min = m[i][j];
        }
      }
    }
    return min;
  }

  static double getAverage(Matrix<double> array) {
     double ave = 0.0;
     for (int i=0; i<array.cols; i++) {
      for (int j=0; j<array.rows; j++) {
        ave += array[i][j];
      }
    }
    return ave / array.size;
  }
}