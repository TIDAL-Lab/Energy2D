part of Energy2D;


class Matrix {
  
  int rows;
  int cols;
  
  List<List<double>> matrix;
 
  Random rand = new Random();
  
  
  Matrix(int r, int c) {
    rows = r;
    cols = c;
    matrix = new List<List<double>>();
    
    for (int i=0; i<rows; i++) {
      for (int j=0; j<cols; j++) {
        
        // create a new row
        List list = new List<double>.filled(cols, 0.0);
        
        // add the row to the list of rows
        matrix.add(list);
      }
    }
  }
    
    
  double getValue(int row, int col) {
    return matrix[row][col];
  }
    
    
  void randomize(double min, double max) {
    for (int i=0; i<rows; i++) {
      for (int j=0; j<cols; j++) {
        double value = rand.nextDouble() * (max - min) + min;
        matrix[i][j] = value;
      }
    }
  }
}