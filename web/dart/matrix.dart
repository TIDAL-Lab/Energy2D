part of Energy2D;


class Matrix<T> {
  
  List<List<T>> matrix;
  
  int rows, cols;
  
  Matrix(this.rows, this.cols, [ T defaultValue = null ]) {
    matrix = new List<List<T>>(cols);
    for (int i=0; i<cols; i++) {
      matrix[i] = new List<T>(rows);
      for (int j=0; j<rows; j++) {
        matrix[i][j] = defaultValue;        
      }
    }
  }
  
  
  void fill(T value) {
    for (int i=0; i<rows; i++) {
      for (int j=0; j<cols; j++) {
        matrix[i][j] = value;
      }
    }
  }
  
  
  List<T> operator[](int i) {
    return matrix[i];
  }
  
  
  int get size => rows * cols;
  
  
  void copyFrom(Matrix<T> source) {
    if (source.rows == rows && source.cols == cols) {
      for (int i=0; i<rows; i++) {
        for (int j=0; j<cols; j++) {
          matrix[i][j] = source.matrix[i][j];
        }
      }
    }
  }
  
}