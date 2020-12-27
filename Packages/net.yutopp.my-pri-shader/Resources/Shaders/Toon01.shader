Shader "MyPriShader/Toon01"
{
    Properties
    {
        _BaseColor("BaseColor", Color) = (1,1,1,1)
        _MainTex ("Lit (RGB)", 2D) = "white" {}
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

            uniform float4 _BaseColor;
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord0    : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv0          : TEXCOORD0;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv0 = IN.texcoord0;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float4 mainTexColor = tex2D(_MainTex, TRANSFORM_TEX(IN.uv0, _MainTex));
                float4 mainColor = _BaseColor * mainTexColor;

                return mainColor;
            }

            ENDHLSL
        }
    }
}
