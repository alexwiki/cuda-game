#include <stdio.h>
#include <stdlib.h>
#define M 32
#define KNRM  "\x1B[0m"
#define KRED  "\x1B[31m"
#define KGRN  "\x1B[32m"
#define KYEL  "\x1B[33m"
#define KBLU  "\x1B[34m"
#define KMAG  "\x1B[35m"
#define KCYN  "\x1B[36m"
#define KWHT  "\x1B[37m"


__global__ void uni_func(int *A,int width,int *OUT)
{
	__shared__ int ns[32*32];//neighboors state
	int col = blockIdx.x*blockDim.x + threadIdx.x;
//	int row = blockIdx.y*blockDim.y + threadIdx.y;
	int tid =  col;
	//unsigned int tid = threadIdx.x;
	//uni_1d[row*width + col] = me
/*
	ns[tid] = A[row*width + col];
	__syncthreads();


//	int iam = A[row*width + col] ; // κεντρικο κελι

	int iam = ns[tid];
	int n[8];//neighboors

	n[0] = ns[tid-M-1] ;
	n[1] = ns[tid-M] ;
	n[2] = ns[tid-M+1] ;

	n[3] = ns[tid-1] ;
	n[4] = ns[tid+1] ;

	n[5] = ns[tid+M-1] ;
	n[6] = ns[tid+M] ;
	n[7] = ns[tid+M+1] ;
	*/

	bool first_row,last_row,first_col,last_col;
	first_row = col>=0 && col <= width-1;//prwti grammi = 0
	last_row = (col>=(width*width)-width) && (col<=(width*width)-1) ;//teleutaia grammi = 0
	first_col = col%width == 0;//prwti stili = 0
	last_col = col%width == width -1 ;
	if (!(first_row || last_row)){// || first_col || last_col )) {//oxi kadro tou pinaka

			if (tid%2==0){//mono ziga thread fernoun kosmo
				ns[row*width + col] = A[row*width + col];//me
				ns[(row-1)*width + (col)] = A[(row-1)*width + (col)];
				ns[(row-1)*width + (col+1)] = A[(row-1)*width + (col+1)];
				ns[row*width + (col+1)] = A[row*width + (col+1)];
				ns[(row+1)*width + (col)] = A[(row+1)*width + (col)];
				ns[(row+1)*width + (col+1)] = A[(row+1)*width + (col+1)];
			}

			__syncthreads();

			int iam = ns[row*width + col];
			int n[8];//neighboors

			n[0] = ns[(row-1)*width + (col-1)] ;
			n[1] = ns[(row-1)*width + (col)] ;
			n[2] = ns[(row-1)*width + (col+1)] ;

			n[3] = ns[row*width + (col-1)] ;
			n[4] = ns[row*width + (col+1)] ;

			n[5] = ns[(row+1)*width + (col-1)] ;
			n[6] = ns[(row+1)*width + (col)] ;
			n[7] = ns[(row+1)*width + (col+1)] ;


			//on || off || dying
			//Ξεκιναμε να οριζουμε τις συνθηκες αλλαγης καταστασεων:
			int counter_alive=0;
			int counter_dead=0;		// οι 3 μετρητες μας που θα πρεπει να γυρισουν
			int counter_DYING=0;	//στην CPU και θα εκτυπωθουν

			// rules: -1: dying && 0:off && 1:on
		//Στον παρακατω κωδικα μετραμε του alive ,dead ,DYING
		// tsekaroume ean edw einai to lathos ston kwdika

			for (int i = 0; i <= 7; i++)
			{
				if (n[i] != -1)//for sure is not dying - actually is not -1(negative number)
				{
					counter_alive += n[i];//counter_alive = counter_alive + 0/1
				}
				else//
				{
					counter_DYING -= n[i] ;//-0 || -(-1)=+1
				}
			}
			counter_dead = 8 - ( counter_alive + counter_DYING);//all neighboors - not_dying



			if(iam == -1)//i am dying
			{
				iam = 0;//i am off
			}
			else if(iam == 1)//i am on
			{
			 	iam = -1;	//i am dying
			}
			else if(iam == 0 && counter_alive == 2 )//i am off and 2 neighboors on
			{
				iam = 1;	//i will be on


			}

		  if (first_col || last_col ){//sto kadro tou pinaka
				iam = 0;
			}

			OUT[row*width + col] = iam;




			//twra pou to skeutomai to perigramma tou pinaka = 0 mporei na metaferthei kai
			//sto host wste na min gemizoume me if ta thread .... ;)
			//sizita to me alex

	}
	else{
		OUT[row*width + col] = 0;
	}

}

int main() {
	//initialize A
	int i,j;
	int on=0;
	int off=0;
	int dying=0;
	//int  M =  32;
	int N=M*M;//all elements of A
	int A[M][M] ;
	int OUT[M][M] ;
	srand (time(NULL));
	printf("\n....IN MAIN...\n");
	for(i=0;i< M;i++)
	{
		for(j=0;j< M;j++)
		{
			if (i==0 || i==M-1 || j==M-1 || j==0){
				A[i][j] = 0;//to perigramma tou pinaka
				OUT[i][j] = 0;
			}
			else{
				A[i][j]=  rand()%3 -1;
				//if (A[i][j] == -1){printf("%d   ", A[i][j]);}
				//else{printf(" %d   ", A[i][j]);}
				OUT[i][j] = -9;
			}
		}
		//printf("\n");
	}
	for(i=0;i< M;i++)
	{
		for(j=0;j< M;j++)
		{
			if (A[i][j] == -1){printf("%d ", A[i][j]);}
			else{printf(" %d ", A[i][j]);}
		}
		printf("\n");
	}
	//launching kernel

	int *A_device;
	//int A_size = N*sizeof(int) ;
	const size_t A_size = sizeof(int) * size_t(N);
	cudaMalloc((void **)&A_device, A_size);

	int *OUT_device;
	//int A_size = N*sizeof(int) ;
	const size_t OUT_size = sizeof(int) * size_t(N);
	cudaMalloc((void **)&OUT_device, OUT_size);

	cudaMemcpy(A_device, A, A_size, cudaMemcpyHostToDevice);
	cudaMemcpy(OUT_device, OUT, OUT_size, cudaMemcpyHostToDevice);


	//the game is on Mrs. Hatson :)

	int turn = 0;

	while (1){

		if (turn % 2 == 0){//zigos arithmos seiras: A->in, Out->Out
			uni_func<<<M,M>>>(A_device,M,OUT_device);
			cudaMemcpy(OUT, OUT_device, A_size,  cudaMemcpyDeviceToHost);//thats work
			printf("\n\n-------------\n\n%d Time\n\n\n\n",turn);

			for(i=0;i< M;i++)
			{
				for(j=0;j< M;j++)
				{
					if (OUT[i][j] == -1){printf("%s%d ",KRED, OUT[i][j]);}
					else if (OUT[i][j] == 1){printf(" %s%d ",KGRN, OUT[i][j]);}
					else{printf(" %s%d ",KNRM, OUT[i][j]);}

					//make counter
					if (OUT[i][j] == -1){ dying++;}
					else if (OUT[i][j] == 1) {on++;}
					else {off++;}


				}
				printf("\n");
			}
		}
		else{
			uni_func<<<M,M>>>(OUT_device,M,A_device);
			cudaMemcpy(A, A_device, A_size,  cudaMemcpyDeviceToHost);
			printf("\n\n-------------\n\n%d Time\n\n\n\n",turn);

			for(i=0;i< M;i++)
			{
				for(j=0;j< M;j++)
				{
					if (A[i][j] == -1){printf("%s%d ",KRED, A[i][j]);}
					else if (A[i][j]==1){printf(" %s%d ",KGRN, A[i][j]);}
					else {printf(" %s%d ",KNRM, A[i][j]);}

					//make counter
					if (A[i][j] == -1){ dying++;}
					else if (A[i][j] == 1) {on++;}
					else {off++;}
				}
				printf("\n");
			}
		}
		//print counter
		printf("\n%s----------------------------------------------------\n",KNRM);
		printf("counter_alive: %d, counter_dying: %d, counter_dead: %d\n",on,dying,off);
		printf("--------------------------------------------------------\n");
		//counters = 0
		if (off == N){break;}//all elements are off (N=M*M)
		on = 0;
		off = 0;
		dying = 0;
		turn++;//auksanoume seira gia na kalesoume uni_func me allagi eisodwn-eksodwn


	}



	return 0;
}
