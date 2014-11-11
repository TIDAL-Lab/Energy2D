/*
 *   Copyright (C) 2012  The Concord Consortium, Inc.,
 *   25 Love Lane, Concord, MA 01742
 */
part of Energy2D;

/**
 * @author Charles Xie
 * 
 */

class MassBoundary {
  double upper, lower, left, right;
  
  MassBoundary(this.upper, this.lower, this.left, this.right);
  int REFLECTIVE = 0;
  int THROUGH = 1;

}


class SimpleMassBoundary extends MassBoundary {
  SimpleMassBoundary() : super(0.0, 0.0, 0.0, 0.0);
  
}
