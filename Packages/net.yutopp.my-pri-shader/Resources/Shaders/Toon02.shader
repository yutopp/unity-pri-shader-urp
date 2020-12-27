Shader "MyPriShader/Toon02"
{
    Properties
    {
        _BaseColor("BaseColor", Color) = (1,1,1,1)
        _MainTex ("Lit (RGB)", 2D) = "white" {}

        [Header(Shadow)]
        _ShadowTex("Shadow (RGB)", 2D) = "white" {}
        _ShadowColor("ShadowColor", Color) = (1,1,1,1)
        _ShadowGradation("ShadowGradation", Range(0, 1)) = 0.0
        _ShadowShift("ShadowShift", Range(-1, 1)) = 0.0
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            uniform float4 _BaseColor;
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;

            uniform sampler2D _ShadowTex; uniform float4 _ShadowTex_ST;
            uniform float4 _ShadowColor;
            uniform float _ShadowGradation;
            uniform float _ShadowShift;

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL; // OS = object space
                float2 texcoord0    : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv0          : TEXCOORD0;
                float3 normalDirWS  : TEXCOORD1;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv0 = IN.texcoord0;

                VertexNormalInputs normalInput = GetVertexNormalInputs(IN.normalOS);
                OUT.normalDirWS = normalInput.normalWS;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float3 normalDirWS = normalize(IN.normalDirWS);

                Light light = GetMainLight();
                float3 lightDirWS = normalize(light.direction); // 0.0 -> light dir

                // 平行光源と法線の内積を取る。向きが同じほど1
                float NdotL = dot(normalDirWS, lightDirWS);
                float diffuse =  max(0, smoothstep(_ShadowShift, _ShadowGradation + _ShadowShift, NdotL));

                float4 mainTexColor = tex2D(_MainTex, TRANSFORM_TEX(IN.uv0, _MainTex));
                float4 mainColor = diffuse * _BaseColor * mainTexColor;

                float4 shadowColor = (1 - diffuse) * _ShadowColor;

                float4 resultColor = mainColor + shadowColor;
                return resultColor;
            }

            ENDHLSL
        }
    }
}
