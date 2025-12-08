package mx.edu.utez.paqueteria.service;

import com.amazonaws.auth.AWSCredentials;
import com.amazonaws.auth.AWSStaticCredentialsProvider;
import com.amazonaws.auth.BasicAWSCredentials;
import com.amazonaws.auth.BasicSessionCredentials;
import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.AmazonS3ClientBuilder;

import com.amazonaws.services.s3.model.ObjectMetadata;
import com.amazonaws.services.s3.model.PutObjectRequest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.util.UUID;

@Service
public class S3Service {

    @Value("${aws_access_key_id:#{null}}")
    private String accessKey;

    @Value("${aws_secret_access_key:#{null}}")
    private String secretKey;

    @Value("${aws_session_token:#{null}}")
    private String sessionToken;

    @Value("${aws.s3.region}")
    private String region;

    @Value("${aws.s3.bucket}")
    private String bucketName;

    private AmazonS3 s3Client;

    @PostConstruct
    private void initializeAmazon() {
        try {
            System.out.println("----------------------------------------------------------------");
            System.out.println("Intentando iniciar cliente S3 con DefaultAWSCredentialsProviderChain (IAM Roles, Env Vars, etc.)");
            System.out.println("----------------------------------------------------------------");
            // Intentar usar DefaultAWSCredentialsProviderChain
            this.s3Client = AmazonS3ClientBuilder.standard()
                    .withRegion(region)
                    .build();
            // Verificar si el cliente es válido realizando una operación básica
            this.s3Client.listBuckets();
            System.out.println("Cliente S3 inicializado con credenciales heredadas.");
        } catch (Exception e) {
            System.out.println("Cliente S3 no pudo inicializarse con credenciales heredadas");
            System.out.println("Intentando iniciar cliente S3 con credenciales explícitas de application.properties...");
            try {
                AWSCredentials credentials;
                if (sessionToken != null && !sessionToken.isEmpty()) {
                    System.out.println("Usando Session Token proporcionado");
                    credentials = new BasicSessionCredentials(accessKey, secretKey, sessionToken);
                } else {
                    credentials = new BasicAWSCredentials(accessKey, secretKey);
                }
                this.s3Client = AmazonS3ClientBuilder.standard()
                        .withCredentials(new AWSStaticCredentialsProvider(credentials))
                        .withRegion(region)
                        .build();
                System.out.println("Cliente S3 inicializado con credenciales explícitas.");
            } catch (Exception ex) {
                System.err.println("Error al inicializar cliente S3 con credenciales explícitas: " + ex.getMessage());
                throw new IllegalStateException("No se pudo inicializar el cliente S3 con ninguna credencial.", ex);
            }
        }
    }

    public String uploadFile(MultipartFile multipartFile) {
        String fileUrl = "";
        try {
            String fileName = generateFileName(multipartFile);
            fileUrl = "https://" + bucketName + ".s3." + region + ".amazonaws.com/" + fileName;
            uploadFileTos3bucket(fileName, multipartFile);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return fileUrl;
    }

    private String generateFileName(MultipartFile multiPart) {
        return UUID.randomUUID().toString() + "-" + multiPart.getOriginalFilename().replace(" ", "_");
    }

    private void uploadFileTos3bucket(String fileName, MultipartFile file) throws IOException {
        ObjectMetadata metadata = new ObjectMetadata();
        metadata.setContentLength(file.getSize());
        metadata.setContentType(file.getContentType());

        s3Client.putObject(new PutObjectRequest(bucketName, fileName, file.getInputStream(), metadata));
    }
}
