#include <math.h>

/* Matrixes using column major order (as in Fortran) */
#ifndef set_matrix_elt
#define set_matrix_elt(A,r,c,n_rows,value) A[r + n_rows * c] = value
#endif

#ifndef get_matrix_elt
#define get_matrix_elt(A,r,c,n_rows) A[r + n_rows * c]
#endif

/* forward declarations */
int test_Pendulum(double x, double y);
int test_Quaternion(double q0, double q1, double q2, double q3);
int test_35();
void pivot( double *A, int n_rows, int n_cols, int *rowInd, int *colInd );

/* main */
int main()
{
  /* return code */
  int rc;

  /* Pendulum */
  if ( (rc = test_Pendulum(1,0)) != 0) return 1000+rc;
  if ( (rc = test_Pendulum(sqrt(2.0)/2.0,sqrt(2.0)/2.0)) != 0) return 1100+rc;
  if ( (rc = test_Pendulum(0,1)) != 0) return 1200+rc;

  /* Quaternion */
  if ( (rc = test_Quaternion(1,0,0,0)) != 0) return 2000+rc;
  if ( (rc = test_Quaternion(0,1,0,0)) != 0) return 2100+rc;
  if ( (rc = test_Quaternion(0,0,1,0)) != 0) return 2200+rc;
  if ( (rc = test_Quaternion(0,0,0,1)) != 0) return 2300+rc;
  if ( (rc = test_Quaternion(0.1,0.2,0.3,sqrt(1-0.1*0.1-0.2*0.2-0.3*0.3))) != 0) return 2400+rc;

  /* Random Test */
  if ( (rc = test_35()) != 0) return 3000+rc;

  /* everything OK */
  return 0;
}

int test_Pendulum(double x, double y)
{
  /* row and column indices */
  const int n_rows = 1;
  const int n_cols = 2;
  int rowInd[] = {0};
  int colInd[] = {0,1};

  /* Matrix */
  double A[] = {2*x, 2*y};

  /* Pivotisierung */
  pivot(A, n_rows, n_cols, rowInd, colInd);

  /* test result */
  if (rowInd[0] != 0) return 1;
  if (colInd[0] != (x >= y) ? 0 : 1 ) return 10;
  if (colInd[1] != (x >= y) ? 1 : 0 ) return 11;

  /* everything is fine */
  return 0;
}

int test_Quaternion(double q0, double q1, double q2, double q3)
{
  /* row and column indices */
  const int n_rows = 1;
  const int n_cols = 4;
  int rowInd[] = {0};
  int colInd[] = {0,1,2,3};

  /* Matrix */
  double A[] = {2*q0, 2*q1, 2*q2, 2*q3};

  /* Pivotisierung */
  pivot(A, n_rows, n_cols, rowInd, colInd);

  /* test result */
  if (rowInd[0] != 0) return 1;
  if ((colInd[0] < 0) || (colInd[0] > 3)) return 10;
  if (colInd[0] == 0)
    if ((q0 < q1) || (q0 < q2) || (q0 < q3)) return 11;
  if (colInd[0] == 1)
    if ((q1 < q0) || (q1 < q2) || (q1 < q3)) return 12;
  if (colInd[0] == 2)
    if ((q2 < q0) || (q2 < q1) || (q2 < q3)) return 13;
  if (colInd[0] == 3)
    if ((q3 < q0) || (q3 < q1) || (q3 < q2)) return 14;

  /* everything is fine */
  return 0;
}

/* a system that has been generated by random */
int test_35()
{
  /* row and column indices */
  const int n_rows=3;
  const int n_cols=5;
  int rowInd[] = {0,1,2};
  int colInd[] = {0,1,2,3,4};

  /* Matrix (transposed, since columns come first) */
  double A[] = { 14.1886, 42.1761, 91.5736,
                 79.2207, 95.9492, 65.5741,
                  3.5712, 84.9129, 93.3993,
                 67.8735, 75.7740, 74.3132,
                 39.2227, 65.5478, 17.1187 };


  /* Pivotisierung */
  pivot(A, n_rows, n_cols, rowInd, colInd);

  /* test result */
  if (rowInd[0] != 1) return 1;
  if (rowInd[1] != 0) return 2;
  if (rowInd[2] != 2) return 3;
  if (colInd[0] != 1) return 11;
  if (colInd[1] != 2) return 11;
  if (colInd[2] != 0) return 11;
  if (colInd[3] != 3) return 11;
  if (colInd[4] != 4) return 11;

  /* everything is fine */
  return 0;
}
