/*
 *   Copyright (C) 2009  The Concord Consortium, Inc.,
 *   25 Love Lane, Concord, MA 01742
 */
part of Energy2D;


class ThermalBoundary {
  double upper, lower, left, right;

  ThermalBoundary(this.upper, this.lower, this.left, this.right);
}



class NeumannThermalBoundary extends ThermalBoundary {
  NeumannThermalBoundary() : super(0.0, 0.0, 0.0, 0.0);
}


 class DirichletThermalBoundary extends ThermalBoundary {
     DirichletThermalBoundary() : super(3.0, 3.0, 3.0, 3.0);
}
