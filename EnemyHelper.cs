using Godot;
using System;

public partial class EnemyHelper : Node
{

	public int find_best_dir(Vector2 interestVec, Vector2[] vecArr, RayCast2D rayCast2D)
	{
		float[] dots = new float[16];
		int[] danger = new int[16];

		Array.Fill(danger, 0);
		
		for (int i = 0; i < 16; i++)
		{
			dots[i] = dots[i] + interestVec.Dot(vecArr[i]);
			rayCast2D.TargetPosition = vecArr[i] * 16;
			rayCast2D.ForceRaycastUpdate();
			
			if (rayCast2D.IsColliding())
			{
				danger[i] += 10;
				danger[PosMod(i + 1, 16)] += 2;
				danger[PosMod(i - 1, 16)] += 2;
			}
		}

		int bestDir = 0;

		for (int i = 0; i < 16; i++)
		{
			dots[i] -= danger[i];
			if (dots[i] > dots[bestDir])
			{
				bestDir = i;
			}
		}
		
		return bestDir;
	}

	private int PosMod(int x, int m)
	{
		return ((x % m) + m) % m;
	}
}
