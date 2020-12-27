Shader "MyPriShader/Toon03"
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

        [Header(Lim)]
        _LimColor("LimColor", Color) = (1,1,1,1)
        _LimForce("LimForce", Range(0, 1)) = 0.1
        _LimGradation("LimGradation", Range(0, 1)) = 1
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

            uniform float4 _LimColor;
            uniform float _LimForce;
            uniform float _LimGradation;

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
                float3 positionWS   : TEXCOORD2;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv0 = IN.texcoord0;

                VertexNormalInputs normalInput = GetVertexNormalInputs(IN.normalOS);
                OUT.normalDirWS = normalInput.normalWS;

                VertexPositionInputs p = GetVertexPositionInputs(IN.positionOS);
                OUT.positionWS = p.positionWS;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float3 normalDirWS = normalize(IN.normalDirWS);

                Light light = GetMainLight();
                float3 lightDirWS = normalize(light.direction); // 0.0 -> light dir

                // 頂点 ( フラグメントシェーダなので実際は表面 ...) からカメラ方面
                float3 vertToCameraDirWS = normalize(GetCameraPositionWS() - IN.positionWS);

                // 平行光源と法線の内積を取る。向きが同じほど1
                float NdotL = dot(normalDirWS, lightDirWS);
                float diffuse = max(0, smoothstep(_ShadowShift, _ShadowGradation + _ShadowShift, NdotL));

                // 法線と(頂点からカメラ向き)の内積を取る。向きが同じであるほど1。
                float NdotC = dot(normalDirWS, vertToCameraDirWS);
                float4 limSteppedForce = 1 - max(0, smoothstep(0, _LimGradation, NdotC));
                float4 limLightedColor = limSteppedForce * _LimForce * _LimColor;

                float4 mainTexColor = tex2D(_MainTex, TRANSFORM_TEX(IN.uv0, _MainTex));
                float4 mainColor = diffuse * _BaseColor * mainTexColor;

                float4 shadowColor = (1 - diffuse) * _ShadowColor;

                float4 resultColor = mainColor + shadowColor + limLightedColor;
                return resultColor;
            }

            ENDHLSL
        }
    }
}
