/*
 *   Copyright (C) 2009  The Concord Consortium, Inc.,
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

   static final int UPPER = 0;
   static final int RIGHT = 1;
   static final int LOWER = 2;
   static final int Left = 3;

   static final int REFLECTIVE = 0;
   static final int THROUGH = 1;

}
class SimpleMassBoundary extends MassBoundary {

  SimpleMassBoundary() : super(0.0, 0.0, 0.0, 0.0);

}
