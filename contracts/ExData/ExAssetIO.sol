// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 取引所が管理するインセンティブと手数料の算出を行い、入出量を管理する
// * Exchangeでインスタンスを生成して、取引所につき1個だけ持つ

contract ExAssetIO {
    // アクセスキーのアドレスと取引回数のマッピング
    mapping(address => uint256) public accessKeyTransactionCount;

    // アクセスキーのアドレスを格納する配列
    address[] public accessKeyAddresses;

    // 最大取引数を記録する変数
    uint256 public maxTransactionCount;

    // ブロック番号の更新間隔(使ってないけどいる？)
    uint256 public constant BLOCK_UPDATE_INTERVAL = 240;

    // 前回記録したときのブロック番号
    uint256 public previousBlocknumber;

    // 手数料率(相対取引回数率が「X.Y%」だった時、[Y][X]を参照する)
    uint16[10][100] public fees = [
        [500,500,500,500,500,500,500,500,500,500],
        [524,547,570,591,612,632,651,670,689,707],
        [724,741,758,774,790,806,821,836,851,866],
        [880,894,908,921,935,948,961,974,987,1000],
        [1012,1024,1036,1048,1060,1072,1083,1095,1106,1118],
        [1129,1140,1151,1161,1172,1183,1193,1204,1214,1224],
        [1234,1244,1254,1264,1274,1284,1294,1303,1313,1322],
        [1332,1341,1350,1360,1369,1378,1387,1396,1405,1414],
        [1423,1431,1440,1449,1457,1466,1474,1483,1491,1500],
        [1508,1516,1524,1532,1541,1549,1557,1565,1573,1581],
        [1589,1596,1604,1612,1620,1627,1635,1643,1650,1658],
        [1665,1673,1680,1688,1695,1702,1710,1717,1724,1732],
        [1739,1746,1753,1760,1767,1774,1781,1788,1795,1802],
        [1809,1816,1823,1830,1837,1843,1850,1857,1864,1870],
        [1877,1884,1890,1897,1903,1910,1917,1923,1930,1936],
        [1942,1949,1955,1962,1968,1974,1981,1987,1993,2000],
        [2006,2012,2018,2024,2031,2037,2043,2049,2055,2061],
        [2067,2073,2079,2085,2091,2097,2103,2109,2115,2121],
        [2127,2133,2138,2144,2150,2156,2162,2167,2173,2179],
        [2185,2190,2196,2202,2207,2213,2219,2224,2230,2236],
        [2241,2247,2252,2258,2263,2269,2274,2280,2285,2291],
        [2296,2302,2307,2313,2318,2323,2329,2334,2339,2345],
        [2350,2355,2361,2366,2371,2376,2382,2387,2392,2397],
        [2403,2408,2413,2418,2423,2428,2434,2439,2444,2449],
        [2454,2459,2464,2469,2474,2479,2484,2489,2494,2500],
        [2504,2509,2514,2519,2524,2529,2534,2539,2544,2549],
        [2554,2559,2564,2569,2573,2578,2583,2588,2593,2598],
        [2602,2607,2612,2617,2622,2626,2631,2636,2641,2645],
        [2650,2655,2659,2664,2669,2673,2678,2683,2687,2692],
        [2697,2701,2706,2711,2715,2720,2724,2729,2734,2738],
        [2743,2747,2752,2756,2761,2765,2770,2774,2779,2783],
        [2788,2792,2797,2801,2806,2810,2815,2819,2824,2828],
        [2832,2837,2841,2846,2850,2854,2859,2863,2867,2872],
        [2876,2880,2885,2889,2893,2898,2902,2906,2911,2915],
        [2919,2924,2928,2932,2936,2941,2945,2949,2953,2958],
        [2962,2966,2970,2974,2979,2983,2987,2991,2995,3000],
        [3004,3008,3012,3016,3020,3024,3029,3033,3037,3041],
        [3045,3049,3053,3057,3061,3065,3070,3074,3078,3082],
        [3086,3090,3094,3098,3102,3106,3110,3114,3118,3122],
        [3126,3130,3134,3138,3142,3146,3150,3154,3158,3162],
        [3166,3170,3174,3178,3181,3185,3189,3193,3197,3201],
        [3205,3209,3213,3217,3221,3224,3228,3232,3236,3240],
        [3244,3248,3251,3255,3259,3263,3267,3271,3274,3278],
        [3282,3286,3290,3293,3297,3301,3305,3309,3312,3316],
        [3320,3324,3327,3331,3335,3339,3342,3346,3350,3354],
        [3357,3361,3365,3368,3372,3376,3380,3383,3387,3391],
        [3394,3398,3402,3405,3409,3413,3416,3420,3424,3427],
        [3431,3435,3438,3442,3446,3449,3453,3456,3460,3464],
        [3467,3471,3474,3478,3482,3485,3489,3492,3496,3500],
        [3503,3507,3510,3514,3517,3521,3524,3528,3531,3535],
        [3539,3542,3546,3549,3553,3556,3560,3563,3567,3570],
        [3574,3577,3581,3584,3588,3591,3595,3598,3602,3605],
        [3609,3612,3615,3619,3622,3626,3629,3633,3636,3640],
        [3643,3646,3650,3653,3657,3660,3664,3667,3670,3674],
        [3677,3681,3684,3687,3691,3694,3697,3701,3704,3708],
        [3711,3714,3718,3721,3724,3728,3731,3734,3738,3741],
        [3744,3748,3751,3754,3758,3761,3764,3768,3771,3774],
        [3778,3781,3784,3788,3791,3794,3798,3801,3804,3807],
        [3811,3814,3817,3820,3824,3827,3830,3834,3837,3840],
        [3843,3847,3850,3853,3856,3860,3863,3866,3869,3872],
        [3876,3879,3882,3885,3889,3892,3895,3898,3901,3905],
        [3908,3911,3914,3917,3921,3924,3927,3930,3933,3937],
        [3940,3943,3946,3949,3952,3956,3959,3962,3965,3968],
        [3971,3974,3978,3981,3984,3987,3990,3993,3996,4000],
        [4003,4006,4009,4012,4015,4018,4021,4024,4028,4031],
        [4034,4037,4040,4043,4046,4049,4052,4055,4058,4062],
        [4065,4068,4071,4074,4077,4080,4083,4086,4089,4092],
        [4095,4098,4101,4104,4107,4110,4114,4117,4120,4123],
        [4126,4129,4132,4135,4138,4141,4144,4147,4150,4153],
        [4156,4159,4162,4165,4168,4171,4174,4177,4180,4183],
        [4186,4189,4192,4195,4198,4201,4204,4207,4210,4213],
        [4216,4219,4221,4224,4227,4230,4233,4236,4239,4242],
        [4245,4248,4251,4254,4257,4260,4263,4266,4269,4272],
        [4274,4277,4280,4283,4286,4289,4292,4295,4298,4301],
        [4304,4306,4309,4312,4315,4318,4321,4324,4327,4330],
        [4333,4335,4338,4341,4344,4347,4350,4353,4356,4358],
        [4361,4364,4367,4370,4373,4376,4378,4381,4384,4387],
        [4390,4393,4396,4398,4401,4404,4407,4410,4413,4415],
        [4418,4421,4424,4427,4430,4432,4435,4438,4441,4444],
        [4446,4449,4452,4455,4458,4460,4463,4466,4469,4472],
        [4474,4477,4480,4483,4486,4488,4491,4494,4497,4500],
        [4502,4505,4508,4511,4513,4516,4519,4522,4524,4527],
        [4530,4533,4535,4538,4541,4544,4546,4549,4552,4555],
        [4557,4560,4563,4566,4568,4571,4574,4577,4579,4582],
        [4585,4588,4590,4593,4596,4598,4601,4604,4607,4609],
        [4612,4615,4617,4620,4623,4626,4628,4631,4634,4636],
        [4639,4642,4644,4647,4650,4652,4655,4658,4661,4663],
        [4666,4669,4671,4674,4677,4679,4682,4685,4687,4690],
        [4693,4695,4698,4701,4703,4706,4709,4711,4714,4716],
        [4719,4722,4724,4727,4730,4732,4735,4738,4740,4743],
        [4746,4748,4751,4753,4756,4759,4761,4764,4767,4769],
        [4772,4774,4777,4780,4782,4785,4788,4790,4793,4795],
        [4798,4801,4803,4806,4808,4811,4814,4816,4819,4821],
        [4824,4827,4829,4832,4834,4837,4839,4842,4845,4847],
        [4850,4852,4855,4857,4860,4863,4865,4868,4870,4873],
        [4875,4878,4881,4883,4886,4888,4891,4893,4896,4898],
        [4901,4904,4906,4909,4911,4914,4916,4919,4921,4924],
        [4926,4929,4932,4934,4937,4939,4942,4944,4947,4949],
        [4952,4954,4957,4959,4962,4964,4967,4969,4972,4974],
        [4977,4979,4982,4984,4987,4989,4992,4994,4997,5000]
    ];

    // インセンティブ付与率(相対取引回数率が「X.Y%」だった時、[Y][X]を参照する)
    uint16[10][100] public incentives = [
        [10000,10000,10000,9999,9999,9999,9999,9999,9999,9999],
        [9999,9999,9999,9998,9998,9998,9998,9997,9997,9997],
        [9996,9996,9996,9995,9995,9994,9994,9993,9993,9992],
        [9992,9991,9991,9990,9989,9989,9988,9987,9987,9986],
        [9985,9984,9984,9983,9982,9981,9980,9979,9978,9977],
        [9976,9975,9975,9973,9972,9971,9970,9969,9968,9967],
        [9966,9965,9964,9962,9961,9960,9959,9957,9956,9955],
        [9953,9952,9951,9949,9948,9946,9945,9943,9942,9940],
        [9939,9937,9936,9934,9932,9931,9929,9927,9926,9924],
        [9922,9920,9919,9917,9915,9913,9911,9909,9907,9905],
        [9903,9901,9900,9897,9895,9893,9891,9889,9887,9885],
        [9883,9881,9879,9876,9874,9872,9870,9867,9865,9863],
        [9860,9858,9856,9853,9851,9848,9846,9843,9841,9838],
        [9836,9833,9831,9828,9825,9823,9820,9817,9815,9812],
        [9809,9806,9804,9801,9798,9795,9792,9789,9786,9783],
        [9780,9777,9775,9771,9768,9765,9762,9759,9756,9753],
        [9750,9747,9744,9740,9737,9734,9731,9727,9724,9721],
        [9717,9714,9711,9707,9704,9700,9697,9693,9690,9686],
        [9683,9679,9676,9672,9668,9665,9661,9657,9654,9650],
        [9646,9642,9639,9635,9631,9627,9623,9619,9615,9611],
        [9607,9603,9600,9595,9591,9587,9583,9579,9575,9571],
        [9567,9563,9559,9554,9550,9546,9542,9537,9533,9529],
        [9524,9520,9516,9511,9507,9502,9498,9493,9489,9484],
        [9480,9475,9471,9466,9461,9457,9452,9447,9443,9438],
        [9433,9428,9424,9419,9414,9409,9404,9399,9394,9389],
        [9384,9379,9375,9369,9364,9359,9354,9349,9344,9339],
        [9334,9329,9324,9318,9313,9308,9303,9297,9292,9287],
        [9281,9276,9271,9265,9260,9254,9249,9243,9238,9232],
        [9227,9221,9216,9210,9204,9199,9193,9187,9182,9176],
        [9170,9164,9159,9153,9147,9141,9135,9129,9123,9117],
        [9111,9105,9100,9093,9087,9081,9075,9069,9063,9057],
        [9051,9045,9039,9032,9026,9020,9014,9007,9001,8995],
        [8988,8982,8976,8969,8963,8956,8950,8943,8937,8930],
        [8924,8917,8911,8904,8897,8891,8884,8877,8871,8864],
        [8857,8850,8844,8837,8830,8823,8816,8809,8802,8795],
        [8788,8781,8775,8767,8760,8753,8746,8739,8732,8725],
        [8718,8711,8704,8696,8689,8682,8675,8667,8660,8653],
        [8645,8638,8631,8623,8616,8608,8601,8593,8586,8578],
        [8571,8563,8556,8548,8540,8533,8525,8517,8510,8502],
        [8494,8486,8479,8471,8463,8455,8447,8439,8431,8423],
        [8415,8407,8400,8391,8383,8375,8367,8359,8351,8343],
        [8335,8327,8319,8310,8302,8294,8286,8277,8269,8261],
        [8252,8244,8236,8227,8219,8210,8202,8193,8185,8176],
        [8168,8159,8151,8142,8133,8125,8116,8107,8099,8090],
        [8081,8072,8064,8055,8046,8037,8028,8019,8010,8001],
        [7992,7983,7975,7965,7956,7947,7938,7929,7920,7911],
        [7902,7893,7884,7874,7865,7856,7847,7837,7828,7819],
        [7809,7800,7791,7781,7772,7762,7753,7743,7734,7724],
        [7715,7705,7696,7686,7676,7667,7657,7647,7638,7628],
        [7618,7608,7599,7589,7579,7569,7559,7549,7539,7529],
        [7519,7509,7500,7489,7479,7469,7459,7449,7439,7429],
        [7419,7409,7399,7388,7378,7368,7358,7347,7337,7327],
        [7316,7306,7296,7285,7275,7264,7254,7243,7233,7222],
        [7212,7201,7191,7180,7169,7159,7148,7137,7127,7116],
        [7105,7094,7084,7073,7062,7051,7040,7029,7018,7007],
        [6996,6985,6975,6963,6952,6941,6930,6919,6908,6897],
        [6886,6875,6864,6852,6841,6830,6819,6807,6796,6785],
        [6773,6762,6751,6739,6728,6716,6705,6693,6682,6670],
        [6659,6647,6636,6624,6612,6601,6589,6577,6566,6554],
        [6542,6530,6519,6507,6495,6483,6471,6459,6447,6435],
        [6423,6411,6400,6387,6375,6363,6351,6339,6327,6315],
        [6303,6291,6279,6266,6254,6242,6230,6217,6205,6193],
        [6180,6168,6156,6143,6131,6118,6106,6093,6081,6068],
        [6056,6043,6031,6018,6005,5993,5980,5967,5955,5942],
        [5929,5916,5904,5891,5878,5865,5852,5839,5826,5813],
        [5800,5787,5775,5761,5748,5735,5722,5709,5696,5683],
        [5670,5657,5644,5630,5617,5604,5591,5577,5564,5551],
        [5537,5524,5511,5497,5484,5470,5457,5443,5430,5416],
        [5403,5389,5376,5362,5348,5335,5321,5307,5294,5280],
        [5266,5252,5239,5225,5211,5197,5183,5169,5155,5141],
        [5127,5113,5100,5085,5071,5057,5043,5029,5015,5001],
        [4987,4973,4959,4944,4930,4916,4902,4887,4873,4859],
        [4844,4830,4816,4801,4787,4772,4758,4743,4729,4714],
        [4700,4685,4671,4656,4641,4627,4612,4597,4583,4568],
        [4553,4538,4524,4509,4494,4479,4464,4449,4434,4419],
        [4404,4389,4375,4359,4344,4329,4314,4299,4284,4269],
        [4254,4239,4224,4208,4193,4178,4163,4147,4132,4117],
        [4101,4086,4071,4055,4040,4024,4009,3993,3978,3962],
        [3947,3931,3916,3900,3884,3869,3853,3837,3822,3806],
        [3790,3774,3759,3743,3727,3711,3695,3679,3663,3647],
        [3631,3615,3600,3583,3567,3551,3535,3519,3503,3487],
        [3471,3455,3439,3422,3406,3390,3374,3357,3341,3325],
        [3308,3292,3276,3259,3243,3226,3210,3193,3177,3160],
        [3144,3127,3111,3094,3077,3061,3044,3027,3011,2994],
        [2977,2960,2944,2927,2910,2893,2876,2859,2842,2825],
        [2808,2791,2775,2757,2740,2723,2706,2689,2672,2655],
        [2638,2621,2604,2586,2569,2552,2535,2517,2500,2483],
        [2465,2448,2431,2413,2396,2378,2361,2343,2326,2308],
        [2291,2273,2256,2238,2220,2203,2185,2167,2150,2132],
        [2114,2096,2079,2061,2043,2025,2007,1989,1971,1953],
        [1935,1917,1900,1881,1863,1845,1827,1809,1791,1773],
        [1755,1737,1719,1700,1682,1664,1646,1627,1609,1591],
        [1572,1554,1536,1517,1499,1480,1462,1443,1425,1406],
        [1388,1369,1351,1332,1313,1295,1276,1257,1239,1220],
        [1201,1182,1164,1145,1126,1107,1088,1069,1050,1031],
        [1012,993,974,955,936,917,898,879,860,841],
        [822,803,783,764,745,726,707,687,668,649],
        [629,610,590,571,552,532,513,493,474,454],
        [435,415,395,376,356,337,317,297,278,258],
        [uint16(238), uint16(218), uint16(198), uint16(179), uint16(159), uint16(139), uint16(119), uint16(100), uint16(100), uint16(100)]  // uint8で扱える値を明示的にuint16にキャストしておく
    ];

    // アクセスキーの取引回数を記録する
    function recordTradeTransaction(address _accessKeyAddress, uint256 _transactionCount) public {
        uint256 currentBlockNumber = block.number;

        // アクセスキーのアドレスが未記録の場合、配列に追加
        if (accessKeyTransactionCount[_accessKeyAddress] == 0) {
            accessKeyAddresses.push(_accessKeyAddress);
        }

        // 取引回数を更新
        accessKeyTransactionCount[_accessKeyAddress] = _transactionCount;

        // ブロック番号が更新間隔分離れた場合、リセットを掛けて改めて記録上のすべてから最大数を特定する
        if(currentBlockNumber - previousBlocknumber >= BLOCK_UPDATE_INTERVAL) {
            maxTransactionCount = resetMaxTransactionCount();
        } else { 
            // 特に更新間隔に関係なく最大数の更新を試みる
            if (accessKeyTransactionCount[_accessKeyAddress] > maxTransactionCount) {
                maxTransactionCount = accessKeyTransactionCount[_accessKeyAddress];
            }
        }
    }

    // 最大取引数をリセットする
    function resetMaxTransactionCount() public view returns (uint256) {
        // 最大取引数を保持する一時変数
        uint256 tempMaxTransactionCount = 0;

        // すべてのアクセスキーの取引回数を参照し、最大値を更新
        for (uint256 i = 0; i < accessKeyAddresses.length; i++) {
            if (accessKeyTransactionCount[accessKeyAddresses[i]] > tempMaxTransactionCount) {
                tempMaxTransactionCount = accessKeyTransactionCount[accessKeyAddresses[i]];
            }
        }

        return tempMaxTransactionCount;
    }

    // 与えられた取引回数の最大取引数に対する割合(千分率)を返す　(相対取引回数率の計算)
    function getTransactionCountRatio(uint256 _transactionCount) public view returns (uint256) {
        // 最大取引数を
        uint256 _maxTransactionCount = maxTransactionCount;
        _maxTransactionCount = _maxTransactionCount == 0 ? 1 : _maxTransactionCount;    // ゼロ除算を避けるため、_transactionCountが0の場合は1として扱う

        // 割合を計算
        uint256 ratio = (_transactionCount * 1000) / _maxTransactionCount;
        return ratio;
    }

    // 取引手数料を導出
    function calculateTransactionFee(uint256 _transactionCount) external view returns (uint256) {
        uint256 ratio = getTransactionCountRatio(_transactionCount);
        return uint256(fees[ratio % 10][ratio / 10]);
    }

    // インセンティブ付与率を導出
    function calculateIncentive(uint256 _transactionCount) external view returns (uint256) {
        uint256 ratio = getTransactionCountRatio(_transactionCount);
        return uint256(incentives[ratio % 10][ratio / 10]);
    }
}